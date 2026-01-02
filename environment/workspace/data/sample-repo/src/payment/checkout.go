package payment

import (
    "fmt"
    "net/http"
)

type CheckoutService struct {
    apiKey string
}

func (c *CheckoutService) ProcessPayment(amount float64) error {
    fmt.Printf("Processing payment: $%.2f\n", amount)
    return nil
}