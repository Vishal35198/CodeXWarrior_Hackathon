CREATE TABLE IF NOT EXISTS customerInfo (
    person_customer_id SERIAL PRIMARY KEY,
    person_first_name VARCHAR(50) NOT NULL,
    person_last_name VARCHAR(50) NOT NULL,
    person_email VARCHAR(255) UNIQUE NOT NULL,
    person_phone_number VARCHAR(20),
    person_date_of_birth DATE,
    person_gender CHAR(1),
    person_registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    person_last_login TIMESTAMP,
    person_is_premium BOOLEAN DEFAULT FALSE,
    person_loyalty_points INT DEFAULT 0,
    person_preferred_language VARCHAR(20),
    person_occupation VARCHAR(100),
    person_income NUMERIC(10,2),
    person_marital_status VARCHAR(20),
    
    -- Address Fields
    address_street VARCHAR(255),
    address_city VARCHAR(100),
    address_state VARCHAR(100),
    address_country VARCHAR(100),
    address_postalcode VARCHAR(20),

    -- Account & Payment Info
    account_account_balance NUMERIC(12,2) DEFAULT 0.00,
    account_preferred_payment_method VARCHAR(50),
    account_card_last_four VARCHAR(4),
    account_card_expiry DATE,
    account_has_active_subscription BOOLEAN DEFAULT FALSE,

    -- Shopping Preferences
    preferences_favorite_category VARCHAR(100),
    preferences_avg_spent_per_order NUMERIC(10,2),
    preferences_total_orders INT DEFAULT 0,
    preferences_last_order_date TIMESTAMP,
    preferences_wishlist_items INT DEFAULT 0,
    preferences_newsletter_subscription BOOLEAN DEFAULT TRUE,
    preferences_referral_code VARCHAR(20),

    -- Security & Communication
    securitypassword_hash TEXT NOT NULL,
    security_question VARCHAR(255),
    security_answer_hash TEXT,
    securitytwo_factor_enabled BOOLEAN DEFAULT FALSE,
    securitysms_notifications BOOLEAN DEFAULT TRUE,
    securityemail_notifications BOOLEAN DEFAULT TRUE,
    security_account_status VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS campaigns (
    campaign_id SERIAL PRIMARY KEY,
    campaign_name VARCHAR(255) NOT NULL,
    campaign_type VARCHAR(50) NOT NULL,
    campaign_status VARCHAR(20),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    budget NUMERIC(12,2),
    actual_spent NUMERIC(12,2) DEFAULT 0.00,
    target_audience VARCHAR(255), -- e.g., 'New Users', 'Returning Customers', 'High Spenders'
    total_reach INT DEFAULT 0, -- Number of people targeted
    impressions INT DEFAULT 0, -- Number of times campaign was viewed
    clicks INT DEFAULT 0, -- Clicks on campaign link
    conversions INT DEFAULT 0, -- Number of successful purchases
    revenue_generated NUMERIC(12,2) DEFAULT 0.00,
    discount_code VARCHAR(50), -- Discount code used in campaign if applicable
    discount_value NUMERIC(10,2), -- Discount value associated with the campaign
    email_open_rate DECIMAL(5,2) , -- Open rate percentage
    email_click_through_rate DECIMAL(5,2) , -- CTR percentage
    cost_per_acquisition NUMERIC(10,2) DEFAULT 0.00, -- CPA metric
    roi DECIMAL(10,2) GENERATED ALWAYS AS ((revenue_generated - actual_spent) / NULLIF(actual_spent, 0) * 100) STORED -- ROI percentage
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_unique_identifier SERIAL PRIMARY KEY,
    
    official_supplier_business_name VARCHAR(255) NOT NULL,
    registered_business_address VARCHAR(255),
    primary_contact_person_name VARCHAR(255),
    primary_contact_phone_number VARCHAR(20),
    primary_contact_email_address VARCHAR(255) UNIQUE,
    supplier_country_of_operation VARCHAR(100),
    supplier_tax_identification_number VARCHAR(50),
    preferred_payment_terms_description TEXT,
    total_number_of_products_supplied INT DEFAULT 0,
    average_supplier_rating DECIMAL(3,2) DEFAULT 0.0
);

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    person_customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipping_date TIMESTAMP,
    delivery_date TIMESTAMP,
    order_status VARCHAR(50),
    total_amount NUMERIC(10,2) NOT NULL,
    discount_applied NUMERIC(10,2) DEFAULT 0.00,
    tax_amount NUMERIC(10,2) DEFAULT 0.00,
    shipping_fee NUMERIC(10,2) DEFAULT 0.00,
    payment_status VARCHAR(50),
    payment_method VARCHAR(50),
    tracking_number VARCHAR(50) UNIQUE,
    shipping_address_street VARCHAR(255),
    shipping_address_city VARCHAR(100),
    shipping_address_state VARCHAR(100),
    shipping_address_country VARCHAR(100),
    shipping_address_postalcode VARCHAR(20),
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Removed ON UPDATE CURRENT_TIMESTAMP (PostgreSQL does not support it)
    campaign_id INT,

    CONSTRAINT fk_orders_customer FOREIGN KEY (person_customer_id) REFERENCES customerInfo(person_customer_id) ON DELETE CASCADE,  -- Added comma
    CONSTRAINT fk_orders_campaign FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id) ON DELETE SET NULL
);


CREATE TABLE IF NOT EXISTS order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity INT,
    price_per_unit NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(10,2) GENERATED ALWAYS AS (quantity * price_per_unit) STORED,
    item_status VARCHAR(50),
    warranty_period INT,
    return_period INT,
    is_returnable BOOLEAN DEFAULT TRUE,
    is_replacement_available BOOLEAN DEFAULT FALSE,
    discount_applied NUMERIC(10,2) DEFAULT 0.00,
    tax_amount NUMERIC(10,2) DEFAULT 0.00,
    shipping_fee NUMERIC(10,2) DEFAULT 0.00,
    item_weight NUMERIC(10,2), -- in kg
    item_dimensions VARCHAR(100), -- e.g., "10x5x2 cm"
    manufacturer VARCHAR(255),

    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS events (
    event_id SERIAL PRIMARY KEY,
    person_customer_id INT,  -- Links to customerInfo
    order_id INT,            -- Links to orders (if event is order-related)
    order_item_id INT,       -- Links to order_items (if event is item-specific)
    
    event_type VARCHAR(50) NOT NULL,
    
    device_platform VARCHAR(20),
    device_type VARCHAR(50),  -- 'Mobile', 'Desktop', 'Tablet', 'POS Machine' (for offline)
    device_browser VARCHAR(100), -- e.g., 'Chrome', 'Safari', 'Firefox', 'Edge'
    device_os VARCHAR(50),  -- e.g., 'Windows', 'iOS', 'Android'
    device_app_version VARCHAR(20), -- Stores mobile app version if applicable
    device_ip_address VARCHAR(45),  -- Store IPv4 or IPv6
    location_city VARCHAR(100),
    location_country VARCHAR(100),
    session_id VARCHAR(255), -- Unique session tracking for web/app
    referral_source VARCHAR(255), -- Source of visit (Google, Facebook, Direct, etc.)
    utm_campaign VARCHAR(255), -- Marketing campaign tracking
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Additional Engagement Metrics
    page_url TEXT, -- URL of the page visited
    time_spent_seconds INT, -- Time spent on action
    click_count INT DEFAULT 0, -- Number of clicks in an interaction
    scroll_depth_percentage INT, -- How far a user scrolled
    
    -- Order & Cart Interaction Data
    cart_value NUMERIC(10,2), -- Total cart value when event occurred
    payment_method VARCHAR(50),
    discount_applied NUMERIC(10,2) DEFAULT 0.00, -- Discount at the time of order

    -- Support & Feedback
    support_ticket_id VARCHAR(50), -- If the event is related to customer support
    review_rating INT, -- User rating for review event
    review_comment TEXT, -- Review content
    return_reason VARCHAR(255), -- Reason for return if applicable
    
    -- Notifications & Promotions
    email_opened BOOLEAN DEFAULT FALSE, -- Whether the user opened an email
    push_notification_clicked BOOLEAN DEFAULT FALSE, -- If a push notification was clicked
    coupon_code_used VARCHAR(50), -- Coupon applied if any
    survey_completed BOOLEAN DEFAULT FALSE, -- If the user completed a survey

    event_metadata TEXT,  -- Optional field for additional JSON-like details

    -- Foreign Keys
    CONSTRAINT fk_events_customer FOREIGN KEY (person_customer_id) REFERENCES customerInfo(person_customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_events_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_events_order_item FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id) ON DELETE SET NULL
);




CREATE TABLE IF NOT EXISTS products (
    unique_product_identifier SERIAL PRIMARY KEY,
    
    product_display_name VARCHAR(255) NOT NULL,
    detailed_product_description TEXT,
    product_category_primary VARCHAR(100) NOT NULL,
    product_category_secondary VARCHAR(100),
    global_brand_affiliation VARCHAR(100),
    model_identification_code VARCHAR(100),
    stock_keeping_unit_identifier VARCHAR(50) UNIQUE,
    universal_product_code VARCHAR(50) UNIQUE, 
    european_article_number VARCHAR(50) UNIQUE, 
    international_standard_book_number VARCHAR(50) UNIQUE, 
    
    standard_retail_price_including_tax NUMERIC(10,2) NOT NULL,
    promotional_discounted_price NUMERIC(10,2),
    percentage_discount_applied DECIMAL(5,2),
    applicable_value_added_tax DECIMAL(5,2),
    currency_of_transaction VARCHAR(10) DEFAULT 'USD',
    
    available_stock_quantity_in_units INT NOT NULL,
    minimum_threshold_for_restocking INT,
    estimated_replenishment_date DATE,
    associated_supplier_reference_id INT, 
    warehouse_storage_location_details VARCHAR(255),
    production_batch_identifier VARCHAR(100),
    
    net_weight_in_kilograms DECIMAL(10,3),
    physical_length_in_centimeters DECIMAL(10,2),
    physical_width_in_centimeters DECIMAL(10,2),
    physical_height_in_centimeters DECIMAL(10,2),
    volumetric_measurement_in_liters DECIMAL(10,2),
    
    predominant_color_description VARCHAR(50),
    designated_size_variation VARCHAR(50),
    primary_material_composition VARCHAR(100),
    stylistic_representation VARCHAR(100),
    intended_user_demographic VARCHAR(20),
    
    estimated_battery_backup_duration VARCHAR(50),
    energy_consumption_rating VARCHAR(50),
    supported_connectivity_protocols VARCHAR(100),
    embedded_processor_specifications VARCHAR(100),
    integrated_memory_configuration VARCHAR(50),
    total_storage_capacity_details VARCHAR(50),
    
    indexed_search_keywords_for_product TEXT,
    optimized_meta_title_for_seo VARCHAR(255),
    search_engine_meta_description TEXT,
    product_demonstration_video_link TEXT,
    featured_product_flag BOOLEAN DEFAULT FALSE,
    
    aggregate_customer_review_rating DECIMAL(3,2) DEFAULT 0.0,
    total_number_of_verified_reviews INT DEFAULT 0,
    standard_warranty_duration VARCHAR(50),
    comprehensive_return_policy_description TEXT,
    
    shipping_weight_measurement_in_kilograms DECIMAL(10,3),
    fragile_item_indicator BOOLEAN DEFAULT FALSE,
    perishable_product_flag BOOLEAN DEFAULT FALSE,
    expected_lead_time_in_business_days INT,
    
    active_product_status BOOLEAN DEFAULT TRUE,
    official_product_release_date DATE,
    official_product_discontinuation_date DATE,
    
    legal_manufacturer_entity_name VARCHAR(255),
    country_of_product_origin VARCHAR(100),
    estimated_production_cost_per_unit NUMERIC(10,2),
    
    certified_regulatory_compliance_details TEXT,
    environmentally_sustainable_product BOOLEAN DEFAULT FALSE,
    applicable_warranty_coverage_type VARCHAR(50),
    
    CONSTRAINT fk_products_supplier FOREIGN KEY (associated_supplier_reference_id) REFERENCES suppliers(supplier_unique_identifier) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS customers_loyalty_program (
    loyalty_membership_unique_identifier SERIAL PRIMARY KEY,
    
    associated_customer_reference_id INT NOT NULL,
    loyalty_program_tier_level VARCHAR(50),
    accumulated_loyalty_points_balance INT DEFAULT 0,
    last_loyalty_point_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    eligible_for_special_promotions BOOLEAN DEFAULT FALSE,
    
    initial_enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_loyalty_tier_upgrade_date TIMESTAMP,
    next_loyalty_tier_evaluation_date TIMESTAMP,
    expiration_date_of_loyalty_points TIMESTAMP,
    
    total_discount_amount_redeemed NUMERIC(10,2) DEFAULT 0.00,
    lifetime_loyalty_points_earned INT DEFAULT 0,
    lifetime_loyalty_points_redeemed INT DEFAULT 0,
    
    exclusive_coupon_codes_assigned TEXT,
    customer_birthday_special_discount BOOLEAN DEFAULT FALSE,
    personalized_product_recommendations JSON,
    
    annual_loyalty_spending_threshold NUMERIC(10,2),
    free_shipping_eligibility BOOLEAN DEFAULT FALSE,
    anniversary_reward_voucher_status BOOLEAN DEFAULT FALSE,
    
    customer_feedback_engagement_score DECIMAL(5,2),
    bonus_loyalty_points_last_month INT DEFAULT 0,
    
    referral_bonus_points_earned INT DEFAULT 0,
    referred_friends_count INT DEFAULT 0,
    
    extra_reward_credits_from_surveys INT DEFAULT 0,
    special_event_invitation_status BOOLEAN DEFAULT FALSE,
    
    redemption_activity_log JSON,
    last_redemption_date TIMESTAMP,
    
    preferred_communication_channel VARCHAR(50),
    participation_in_exclusive_beta_testing BOOLEAN DEFAULT FALSE,
    exclusive_member_early_access BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (associated_customer_reference_id) REFERENCES customerInfo(person_customer_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_reviews_and_ratings (
    review_unique_identifier SERIAL PRIMARY KEY,
    
    referenced_product_identifier INT NOT NULL,
    reviewing_customer_identifier INT NOT NULL,
    
    customer_review_submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    textual_review_feedback TEXT,
    submitted_review_star_rating DECIMAL(3,2) DEFAULT 0.00,
    
    verification_status_of_reviewer BOOLEAN DEFAULT FALSE,
    number_of_helpful_votes_received INT DEFAULT 0,
    flagged_as_inappropriate BOOLEAN DEFAULT FALSE,
    
    contains_multimedia_content BOOLEAN DEFAULT FALSE,
    associated_review_image_urls TEXT,
    associated_review_video_links TEXT,
    
    sentiment_analysis_score DECIMAL(5,2),
    keywords_extracted_from_review TEXT,
    length_of_review_in_characters INT,
    
    previous_product_purchases_count INT DEFAULT 0,
    return_request_status BOOLEAN DEFAULT FALSE,
    
    response_from_brand_or_seller TEXT,
    response_submission_date TIMESTAMP,
    
    additional_comments_by_other_users JSON,
    user_has_edited_review BOOLEAN DEFAULT FALSE,
    
    total_number_of_edits_made INT DEFAULT 0,
    review_approval_moderation_status VARCHAR(50),
    review_moderator_notes TEXT,
    
    FOREIGN KEY (referenced_product_identifier) REFERENCES products(unique_product_identifier) ON DELETE CASCADE,
    FOREIGN KEY (reviewing_customer_identifier) REFERENCES customerInfo(person_customer_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS transactions_and_payments (
    transaction_unique_identifier SERIAL PRIMARY KEY,
    
    linked_order_reference_identifier INT NOT NULL,
    corresponding_customer_reference_identifier INT NOT NULL,
    
    total_transaction_amount NUMERIC(10,2) NOT NULL,
    applied_discount_value NUMERIC(10,2) DEFAULT 0.00,
    final_billed_amount NUMERIC(10,2) NOT NULL,
    
    transaction_status VARCHAR(50),
    transaction_date_and_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    payment_method_used VARCHAR(50),
    payment_gateway_used VARCHAR(100),
    transaction_authorization_code VARCHAR(100),
    
    billing_address_street VARCHAR(255),
    billing_address_city VARCHAR(100),
    billing_address_state VARCHAR(100),
    billing_address_country VARCHAR(100),
    billing_address_zip_code VARCHAR(20),
    
    shipping_address_street VARCHAR(255),
    shipping_address_city VARCHAR(100),
    shipping_address_state VARCHAR(100),
    shipping_address_country VARCHAR(100),
    shipping_address_zip_code VARCHAR(20),
    
    transaction_currency_code VARCHAR(10) DEFAULT 'USD',
    foreign_exchange_conversion_rate DECIMAL(10,4),
    
    refund_status BOOLEAN DEFAULT FALSE,
    refund_initiation_date TIMESTAMP,
    refund_amount NUMERIC(10,2),
    
    chargeback_request_status BOOLEAN DEFAULT FALSE,
    chargeback_dispute_reason TEXT,
    chargeback_resolution_status VARCHAR(50),
    
    associated_loyalty_points_earned INT DEFAULT 0,
    gift_card_or_store_credit_usage BOOLEAN DEFAULT FALSE,
    applied_gift_card_code VARCHAR(50),
    
    recurring_billing_flag BOOLEAN DEFAULT FALSE,
    installment_payment_status BOOLEAN DEFAULT FALSE,
    
    first_time_customer_transaction BOOLEAN DEFAULT FALSE,
    transaction_frequency_category VARCHAR(50),
    
    digital_wallet_used VARCHAR(50),
    cryptocurrency_payment_flag BOOLEAN DEFAULT FALSE,
    cryptocurrency_type VARCHAR(50),
    
    alternative_payment_method_used VARCHAR(50),
    
    promotional_offer_applied BOOLEAN DEFAULT FALSE,
    special_financing_option_used BOOLEAN DEFAULT FALSE,
    
    customer_feedback_on_transaction TEXT,
    transaction_review_score DECIMAL(3,2),
    
    is_transaction_fraudulent BOOLEAN DEFAULT FALSE,
    fraud_detection_flagged BOOLEAN DEFAULT FALSE,
    fraud_detection_notes TEXT,
    
    FOREIGN KEY (linked_order_reference_identifier) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (corresponding_customer_reference_identifier) REFERENCES customerInfo(person_customer_id) ON DELETE SET NULL
);

-- Inventory table to track stock of products
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    referenced_product_id INT NOT NULL,
    quantity INT NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    warehouse_location VARCHAR(255),
    stock_threshold INT DEFAULT 10,
    safety_stock INT DEFAULT 5,
    supplier_id INT,
    last_restock_date TIMESTAMP,
    expected_restock_date TIMESTAMP,
    purchase_price NUMERIC(10,2),
    bulk_discount NUMERIC(10,2) DEFAULT 0.00,
    storage_temperature VARCHAR(50),
    shelf_life INT,
    batch_number VARCHAR(50),
    expiry_date DATE,
    stock_status VARCHAR(50) DEFAULT 'Available',
    last_inventory_audit_date TIMESTAMP,
    inventory_adjustment_reason TEXT,
    damaged_stock INT DEFAULT 0,
    inbound_shipment_tracking VARCHAR(100),
    outbound_shipment_tracking VARCHAR(100),
    inventory_turnover_rate DECIMAL(10,2) GENERATED ALWAYS AS 
        (quantity / NULLIF(safety_stock, 0)) STORED,
    last_sold_date TIMESTAMP,
    FOREIGN KEY (referenced_product_id) REFERENCES products(unique_product_identifier) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_unique_identifier) ON DELETE SET NULL
);

-- Shipping table to track order shipments
CREATE TABLE IF NOT EXISTS shipping (
    id SERIAL PRIMARY KEY,
    fk_order_id INT NOT NULL,
    shipping_address TEXT NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(100) NOT NULL,
    shipping_zipcode VARCHAR(20) NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,
    shipping_status VARCHAR(50) CHECK (shipping_status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled')),
    tracking_number VARCHAR(255) UNIQUE,
    estimated_delivery DATE,
    shipped_date TIMESTAMP,
    carrier VARCHAR(100),
    shipping_cost DECIMAL(10,2) CHECK (shipping_cost >= 0),
    FOREIGN KEY (fk_order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- Cart table to store user's selected products before checkout
CREATE TABLE IF NOT EXISTS cart (
    id SERIAL PRIMARY KEY,
    fk_user_id INT NOT NULL,
    fk_product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price_per_unit NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(10,2),  -- Will be updated via trigger
    discount_applied NUMERIC(10,2) DEFAULT 0.00,
    coupon_code VARCHAR(50),
    discounted_total_price NUMERIC(10,2),  -- Will be updated via trigger
    cart_status VARCHAR(20) DEFAULT 'active',
    session_id VARCHAR(255),
    last_activity_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tax_amount NUMERIC(10,2) DEFAULT 0.00,
    shipping_fee NUMERIC(10,2) DEFAULT 0.00,
    estimated_delivery_date DATE,
    is_gift BOOLEAN DEFAULT FALSE,
    gift_message TEXT,
    recommended_products JSON,
    wishlist_flag BOOLEAN DEFAULT FALSE,
    abandonment_reason VARCHAR(255),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_user_id) REFERENCES customerInfo(person_customer_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_product_id) REFERENCES products(unique_product_identifier) ON DELETE CASCADE
);

-- Create ENUM types for PostgreSQL before using them in the table
CREATE TYPE wishlist_status_enum AS ENUM ('active', 'purchased', 'removed');
CREATE TYPE priority_level_enum AS ENUM ('low', 'medium', 'high');
CREATE TYPE added_from_source_enum AS ENUM ('website', 'mobile_app', 'email', 'social_media');

-- Wishlist table to track products a user wants to buy later
CREATE TABLE IF NOT EXISTS wishlist (
    id SERIAL PRIMARY KEY,
    fk_user_id INT NOT NULL,
    fk_product_id INT NOT NULL,
    product_name VARCHAR(255),  -- Stores the product name
    price_at_addition DECIMAL(10,2),  -- Price when added to wishlist
    discount_at_addition DECIMAL(10,2),  -- Discount applied at the time of addition
    wishlist_status wishlist_status_enum DEFAULT 'active',  -- Tracks status of wishlist item
    priority_level priority_level_enum DEFAULT 'medium',  -- Priority of wishlist item
    expected_purchase_date DATE,  -- Expected purchase date if user sets one
    quantity INT DEFAULT 1,  -- Number of units user wants
    notes TEXT,  -- User notes regarding the item
    reminder_set BOOLEAN DEFAULT FALSE,  -- Whether a reminder is set
    reminder_date TIMESTAMP,  -- Reminder date for purchase
    last_viewed_at TIMESTAMP,  -- When user last viewed this item in wishlist
    added_from_source added_from_source_enum,  -- Source of addition
    stock_status_at_addition BOOLEAN DEFAULT TRUE,  -- Whether item was in stock at addition
    category VARCHAR(255),  -- Product category
    brand_name VARCHAR(255),  -- Brand name of the product
    session_id VARCHAR(255),  -- Session ID for tracking user behavior
    currency VARCHAR(10) DEFAULT 'USD',  -- Currency type
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_user_id) REFERENCES customerInfo(person_customer_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_product_id) REFERENCES products(unique_product_identifier) ON DELETE CASCADE
);

-- Refunds and Returns table to track return requests
CREATE TABLE IF NOT EXISTS refunds_returns (
    id SERIAL PRIMARY KEY,
    fk_user_id INT NOT NULL,
    fk_order_id INT NOT NULL,
    fk_product_id INT NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(50) CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Processed')),
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_date TIMESTAMP,  -- Date when refund/return was processed
    refund_amount DECIMAL(10,2),  -- Amount refunded to the user
    refund_method VARCHAR(50) CHECK (refund_method IN ('Original Payment Method', 'Store Credit', 'Bank Transfer')),  -- Refund method
    return_type VARCHAR(50) CHECK (return_type IN ('Full Return', 'Partial Return', 'Exchange')),  -- Type of return
    tracking_number VARCHAR(255),  -- Tracking number for return shipment
    shipping_carrier VARCHAR(255),  -- Carrier handling return shipping
    restocking_fee DECIMAL(10,2) DEFAULT 0.00,  -- Any restocking fees deducted from refund
    return_condition VARCHAR(50) CHECK (return_condition IN ('New', 'Used', 'Damaged', 'Defective')),  -- Condition of the returned item
    customer_notes TEXT,  -- Notes from the customer about the return
    admin_notes TEXT,  -- Notes from the admin handling the return
    refund_status VARCHAR(50) CHECK (refund_status IN ('Initiated', 'In Progress', 'Completed', 'Failed')),  -- Status of the refund process
    return_label_url TEXT,  -- URL for downloading the return shipping label
    is_refundable BOOLEAN DEFAULT TRUE,  -- Whether the product is eligible for a refund
    refund_initiated_by VARCHAR(50) CHECK (refund_initiated_by IN ('Customer', 'Admin', 'System')),  -- Who initiated the refund
    FOREIGN KEY (fk_user_id) REFERENCES customerInfo(person_customer_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_product_id) REFERENCES products(unique_product_identifier) ON DELETE CASCADE
);