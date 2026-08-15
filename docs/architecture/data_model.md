# Data Model — Sales Data Mart

![Sales Data Mart](../images/sales_data_mart.png)

## Star Schema

- **Fact:** `gold.fact_sales` — one row per sales order line
- **Dimensions:** `gold.dim_customers`, `gold.dim_products`

## Fact Table — `gold.fact_sales`

| Column | Type | Description |
|---|---|---|
| `order_number` | string | Unique sales order identifier |
| `product_key` | int (FK) | → `dim_products.product_key` |
| `customer_key` | int (FK) | → `dim_customers.customer_key` |
| `order_date` | date | Date the order was placed |
| `shipping_date` | date | Date the order was shipped |
| `due_date` | date | Expected delivery/due date |
| `sales_amount` | numeric | `quantity * price` |
| `quantity` | int | Quantity sold |
| `price` | numeric | Unit price |

## Dimension — `gold.dim_customers`

`customer_key` (PK), `customer_id`, `customer_number`, `first_name`,
`last_name`, `country`, `marital_status` (`Married`/`Single`), `gender`,
`birthdate`.

## Dimension — `gold.dim_products`

`product_key` (PK), `product_id`, `product_number`, `product_name`,
`category_id`, `category`, `subcategory`, `maintenance` (`Yes`/`No`),
`cost`, `product_line`, `start_date`.

## Business Rule

```
sales_amount = quantity * price
```

Enforced in `sql/silver/transformations/cleanse_crm_sales_details.sql` and
verified in `tests/data_quality/check_gold_sales_calculation.sql`.
