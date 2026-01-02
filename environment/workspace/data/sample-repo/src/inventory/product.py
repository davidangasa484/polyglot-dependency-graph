# CANARY_STRING: polyglot_dep_graph_2025_v1
import json
from typing import List, Dict

class ProductRepository:
    def __init__(self):
        self.products = []
    
    def get_all(self) -> List[Dict]:
        """Get all products"""
        return self.products
    
    def add(self, product: Dict) -> None:
        """Add a product"""
        self.products.append(product)