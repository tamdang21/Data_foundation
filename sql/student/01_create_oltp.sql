CREATE SCHEMA "core";

CREATE TABLE "core"."categories" (
  "category_id" varchar(10) PRIMARY KEY,
  "category_name" varchar(120) NOT NULL,
  "parent_category_id" varchar(10),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE TABLE "core"."customers" (
  "customer_id" varchar(12) PRIMARY KEY,
  "full_name" varchar(150) NOT NULL,
  "email" varchar(200) UNIQUE NOT NULL,
  "phone" varchar(30),
  "city" varchar(100),
  "customer_segment" varchar(30) NOT NULL,
  "status" varchar(20) NOT NULL,
  "source_system" varchar(50) NOT NULL DEFAULT 'unknown',
  "ingested_at" timestamptz NOT NULL DEFAULT (now()),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE TABLE "core"."products" (
  "product_id" varchar(12) PRIMARY KEY,
  "category_id" varchar(10) NOT NULL,
  "product_name" varchar(200) NOT NULL,
  "unit_price" numeric(14,2) NOT NULL CHECK (unit_price >= 0),
  "cost_price" numeric(14,2) NOT NULL CHECK (cost_price >= 0),
  "status" varchar(20) NOT NULL,
  "source_system" varchar(50) NOT NULL DEFAULT 'unknown',
  "ingested_at" timestamptz NOT NULL DEFAULT (now()),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE TABLE "core"."orders" (
  "order_id" varchar(12) PRIMARY KEY,
  "customer_id" varchar(12) NOT NULL,
  "order_date" timestamptz NOT NULL,
  "status" varchar(20) NOT NULL,
  "shipping_city" varchar(100),
  "channel" varchar(20) NOT NULL,
  "order_total" numeric(14,2) NOT NULL CHECK (order_total >= 0),
  "source_system" varchar(50) NOT NULL DEFAULT 'unknown',
  "ingested_at" timestamptz NOT NULL DEFAULT (now()),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE TABLE "core"."order_items" (
  "order_item_id" varchar(16) PRIMARY KEY,
  "order_id" varchar(12) NOT NULL,
  "product_id" varchar(12) NOT NULL,
  "quantity" integer NOT NULL CHECK (quantity > 0),
  "unit_price" numeric(14,2) NOT NULL CHECK (unit_price >= 0),
  "discount_amount" numeric(14,2) NOT NULL CHECK (discount_amount >= 0) DEFAULT 0,
  "source_system" varchar(50) NOT NULL DEFAULT 'unknown',
  "ingested_at" timestamptz NOT NULL DEFAULT (now()),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE TABLE "core"."payments" (
  "payment_id" varchar(12) PRIMARY KEY,
  "order_id" varchar(12) NOT NULL,
  "payment_date" timestamptz NOT NULL,
  "payment_method" varchar(30) NOT NULL,
  "payment_status" varchar(20) NOT NULL,
  "amount" numeric(14,2) NOT NULL CHECK (amount >= 0),
  "source_system" varchar(50) NOT NULL DEFAULT 'unknown',
  "ingested_at" timestamptz NOT NULL DEFAULT (now()),
  "created_at" timestamptz NOT NULL,
  "updated_at" timestamptz NOT NULL
);

CREATE INDEX ON "core"."categories" ("parent_category_id");

CREATE UNIQUE INDEX ON "core"."customers" ("email");

CREATE INDEX ON "core"."products" ("category_id");

CREATE INDEX ON "core"."orders" ("customer_id");

CREATE INDEX ON "core"."orders" ("order_date");

CREATE INDEX ON "core"."order_items" ("order_id");

CREATE INDEX ON "core"."order_items" ("product_id");

CREATE INDEX ON "core"."payments" ("order_id");

COMMENT ON COLUMN "core"."customers"."status" IS 'Allowed values: active, inactive';

COMMENT ON COLUMN "core"."products"."status" IS 'Allowed values: active, inactive, discontinued';

COMMENT ON COLUMN "core"."orders"."status" IS 'Allowed values: pending, confirmed, shipped, completed, cancelled';

COMMENT ON COLUMN "core"."orders"."channel" IS 'Allowed values: web, mobile_app, social';

COMMENT ON TABLE "core"."order_items" IS 'discount_amount must be <= unit_price * quantity';

COMMENT ON COLUMN "core"."payments"."payment_method" IS 'Allowed values: cash, bank_transfer, card, e_wallet';

COMMENT ON COLUMN "core"."payments"."payment_status" IS 'Allowed values: pending, success, failed, refunded';

ALTER TABLE "core"."categories" ADD FOREIGN KEY ("parent_category_id") REFERENCES "core"."categories" ("category_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "core"."products" ADD FOREIGN KEY ("category_id") REFERENCES "core"."categories" ("category_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "core"."orders" ADD FOREIGN KEY ("customer_id") REFERENCES "core"."customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "core"."order_items" ADD FOREIGN KEY ("order_id") REFERENCES "core"."orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "core"."order_items" ADD FOREIGN KEY ("product_id") REFERENCES "core"."products" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "core"."payments" ADD FOREIGN KEY ("order_id") REFERENCES "core"."orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;
-- 1. CHECK: order_date không được ở tương lai
ALTER TABLE core.orders
ADD CONSTRAINT check_order_date
CHECK (order_date <= NOW());


-- 2. CHECK: payment amount không được âm
ALTER TABLE core.payments
ADD CONSTRAINT check_payment_amount
CHECK (amount >= 0);


-- 3. CHECK: order item quantity phải lớn hơn 0
ALTER TABLE core.order_items
ADD CONSTRAINT check_order_item_quantity
CHECK (quantity > 0);


-- 4. DEFAULT cho audit fields
ALTER TABLE core.customers
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE core.customers
ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE core.products
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE core.products
ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE core.orders
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE core.orders
ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE core.order_items
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE core.order_items
ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE core.payments
ALTER COLUMN created_at SET DEFAULT NOW();

ALTER TABLE core.payments
ALTER COLUMN updated_at SET DEFAULT NOW();
