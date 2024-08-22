package main

type WithoutAuthItem struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type WithAuthItem struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Price       int    `json:"price"`
	Description string `json:"description"`
}
