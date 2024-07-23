#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_items>"
    exit 1
fi

N=$1
DB_FILE="items.db"

sqlite3 $DB_FILE <<EOF
CREATE TABLE IF NOT EXISTS items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    price INTEGER,
    description TEXT
);
EOF

insert_item() {
    local name=$1
    local price=$2
    local description=$3
    sqlite3 $DB_FILE <<EOF
INSERT INTO items (name, price, description) VALUES ('$name', $price, '$description');
EOF
}

for i in $(seq 1 $N); do
    name="Item $i"
    price=$((RANDOM % 100 + 1))
    description="Description of $name"
    insert_item "$name" $price "$description"
done

echo "Database populated with $N items."
