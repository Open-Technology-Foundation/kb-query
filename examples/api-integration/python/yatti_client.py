#!/usr/bin/env python3
"""
YaTTI CustomKB Python Client Example

A simple Python client for interacting with the YaTTI API.
"""

import json
import time
from typing import Dict, List, Optional, Any
import requests
from urllib.parse import urlencode


class YaTTIClient:
    """Client for YaTTI CustomKB API."""
    
    def __init__(self, api_key: str, base_url: str = "https://yatti.id/v1/index.php"):
        """
        Initialize the YaTTI client.
        
        Args:
            api_key: Your YaTTI API key
            base_url: API base URL (default: https://yatti.id/v1/index.php)
        """
        self.api_key = api_key
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })
        
    def query(self, 
              kb: str, 
              question: str,
              context_only: bool = False,
              reference: Optional[str] = None,
              model: Optional[str] = None,
              temperature: Optional[float] = None,
              top_k: Optional[int] = None,
              **kwargs) -> Dict[str, Any]:
        """
        Query a knowledgebase.
        
        Args:
            kb: Knowledgebase name
            question: Query text
            context_only: Return only context without LLM processing
            reference: Additional reference text
            model: LLM model to use
            temperature: Response creativity (0.0-1.0)
            top_k: Number of context chunks
            **kwargs: Additional parameters
            
        Returns:
            API response as dictionary
        """
        params = {'q': question}
        
        if context_only:
            params['context_only'] = 'true'
        if reference:
            params['reference'] = reference
        if model:
            params['model'] = model
        if temperature is not None:
            params['temperature'] = temperature
        if top_k is not None:
            params['top_k'] = top_k
            
        # Add any additional parameters
        params.update(kwargs)
        
        url = f"{self.base_url}/{kb}"
        response = self.session.get(url, params=params)
        response.raise_for_status()
        
        return response.json()
    
    def list_knowledgebases(self) -> List[Dict[str, Any]]:
        """
        List all available knowledgebases.
        
        Returns:
            List of knowledgebase information
        """
        response = self.session.get(f"{self.base_url}/list")
        response.raise_for_status()
        data = response.json()
        return data.get('knowledgebases', [])
    
    def get_help(self) -> Dict[str, Any]:
        """
        Get API help information.
        
        Returns:
            API help documentation
        """
        response = self.session.get(f"{self.base_url}/help")
        response.raise_for_status()
        return response.json()
    
    def kb_info(self, kb: str) -> Dict[str, Any]:
        """
        Get information about a specific knowledgebase.
        
        Args:
            kb: Knowledgebase name
            
        Returns:
            Knowledgebase information
        """
        response = self.session.get(f"{self.base_url}/{kb}/info")
        response.raise_for_status()
        return response.json()
    
    def batch_query(self, kb: str, questions: List[str], **kwargs) -> List[Dict[str, Any]]:
        """
        Execute multiple queries in sequence.
        
        Args:
            kb: Knowledgebase name
            questions: List of questions
            **kwargs: Additional parameters for each query
            
        Returns:
            List of responses
        """
        results = []
        for question in questions:
            try:
                result = self.query(kb, question, **kwargs)
                results.append(result)
                time.sleep(0.1)  # Rate limiting
            except Exception as e:
                results.append({
                    'query': question,
                    'error': str(e)
                })
        return results


# Example usage
if __name__ == "__main__":
    # Initialize client
    API_KEY = "yatti_your_api_key_here"
    client = YaTTIClient(API_KEY)
    
    print("=== YaTTI Python Client Examples ===\n")
    
    # 1. List available knowledgebases
    print("1. Available knowledgebases:")
    try:
        kbs = client.list_knowledgebases()
        for kb in kbs:
            print(f"   - {kb['name']}: {kb.get('description', 'No description')}")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 2. Simple query
    print("2. Simple query:")
    try:
        response = client.query("appliedanthropology", "What is dharma?")
        print(f"   Response: {response['response'][:200]}...")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 3. Query with options
    print("3. Advanced query with options:")
    try:
        response = client.query(
            "okusiassociates",
            "What are PMA requirements?",
            model="gpt-4",
            temperature=0.3,
            top_k=20
        )
        print(f"   Response: {response['response'][:200]}...")
        print(f"   Processing time: {response['elapsed_seconds']}s")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 4. Context-only query
    print("4. Context-only retrieval:")
    try:
        response = client.query(
            "okusiassociates",
            "foreign investment regulations",
            context_only=True
        )
        print(f"   Context chunks retrieved: {len(response.get('response', '').split('---'))}")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 5. Query with reference
    print("5. Query with reference context:")
    try:
        reference = "We have 5 foreign shareholders and plan to operate in Jakarta"
        response = client.query(
            "okusiassociates",
            "What type of company should we establish?",
            reference=reference
        )
        print(f"   Response: {response['response'][:200]}...")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 6. Batch queries
    print("6. Batch query example:")
    questions = [
        "What is a PMA company?",
        "What are the capital requirements?",
        "Can foreigners own land?"
    ]
    try:
        results = client.batch_query("okusiassociates", questions, temperature=0.5)
        for i, result in enumerate(results):
            if 'error' in result:
                print(f"   Q{i+1}: Error - {result['error']}")
            else:
                print(f"   Q{i+1}: {result['response'][:100]}...")
    except Exception as e:
        print(f"   Error: {e}")
    print()
    
    # 7. Error handling example
    print("7. Error handling:")
    try:
        response = client.query("nonexistent_kb", "test query")
    except requests.exceptions.HTTPError as e:
        print(f"   HTTP Error: {e}")
        if e.response.status_code == 404:
            print("   Knowledgebase not found")
    except Exception as e:
        print(f"   Unexpected error: {e}")

#fin