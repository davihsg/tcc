package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func WithAuthHandler(router *gin.Engine) {
	router.GET("/items", func(ctx *gin.Context) {
		rows, err := db.Query("SELECT id, name, price, description FROM items")
		if err != nil {
			ctx.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		defer rows.Close()

		var items []WithAuthItem
		for rows.Next() {
			var item WithAuthItem
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
