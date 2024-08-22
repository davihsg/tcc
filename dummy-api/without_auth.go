package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func WithoutAuthHandler(router *gin.Engine) {
	router.GET("/withoutauth/items", func(ctx *gin.Context) {
		rows, err := db.Query("SELECT id, name FROM items LIMIT 40")
		if err != nil {
			ctx.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		defer rows.Close()

		var items []WithoutAuthItem
		for rows.Next() {
			var item WithoutAuthItem
			err = rows.Scan(&item.ID, &item.Name)
			if err != nil {
				ctx.AbortWithError(http.StatusInternalServerError, err)
				return
			}
			items = append(items, item)
		}

		ctx.JSON(http.StatusOK, items)
	})
}
