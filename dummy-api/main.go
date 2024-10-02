package main

import (
	"database/sql"
	"net/http"
	"os"

	_ "github.com/mattn/go-sqlite3"

	"github.com/gin-gonic/gin"
)

type Item struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Price       int    `json:"price"`
	Description string `json:"description"`
}

func Handler(router *gin.Engine, dbPath string) {
	router.GET("/items", func(ctx *gin.Context) {
		db, err := sql.Open("sqlite3", dbPath)
		if err != nil {
			panic(err)
		}
		defer db.Close()

		rows, err := db.Query("SELECT id, name, price, description FROM items")
		if err != nil {
			ctx.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		defer rows.Close()

		var items []Item
		for rows.Next() {
			var item Item
			err = rows.Scan(&item.ID, &item.Name, &item.Price, &item.Description)
			if err != nil {
				ctx.AbortWithError(http.StatusInternalServerError, err)
				return
			}
			items = append(items, item)
		}

		ctx.JSON(http.StatusOK, items)
	})
}

func main() {
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "items.db"
	}

	router := gin.Default()

	Handler(router, dbPath)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8888"
	}

	router.Run(":" + port)
}
