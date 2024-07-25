#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_items>"
    exit 1
fi

N=$1
SVC_USER="server"
DB_DIR="/var/lib/api"
DB_FILE="$DB_DIR/items.db"

if [ ! -d "$DB_DIR" ]; then

    echo "Creating directory $DB_DIR"
    sudo mkdir -p "$DB_DIR"
    sudo chown $SVC_USER:$SVC_USER "$DB_DIR"
    sudo chmod 750 "$DB_DIR"
fi

if [ -f "$DB_FILE" ]; then
    echo "$DB_FILE already exists. Skipping creation and population."
    exit 0
fi

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
    sudo chown $SVC_USER:$SVC_USER "$DB_FILE"
}

for i in $(seq 1 $N); do
    name="Item $i"
    price=$((RANDOM % 100 + 1))
    description="Description of $name"
    insert_item "$name" $price "$description"
done

echo "Database populated with $N items."
