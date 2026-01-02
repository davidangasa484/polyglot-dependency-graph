// CANARY_STRING: polyglot_dep_graph_2025_v1
package inventory

import "fmt"

type StockManager struct {
    inventory map[string]int
}

func NewStockManager() *StockManager {
    return &StockManager{
        inventory: make(map[string]int),
    }
}

func (s *StockManager) UpdateStock(productID string, quantity int) {
    s.inventory[productID] = quantity
    fmt.Printf("Updated stock for %s: %d\n", productID, quantity)
}