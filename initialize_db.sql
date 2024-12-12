-- Step 1: Create the database
CREATE DATABASE IF NOT EXISTS donutdb;

-- Step 2: Switch to the database
USE donutdb;

-- Step 3: Create the donuts table
CREATE TABLE Donuts (
    id INT PRIMARY KEY,
    flavor VARCHAR(255) NOT NULL,
    variety VARCHAR(100) NOT NULL,
    image VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.0
);

-- Step 4: Insert data into the donuts table
INSERT INTO Donuts (id, flavor, variety, image, price) VALUES 
(1, 'Original Glazed Doughnut', 'Glazed', 'https://donutsbucket.s3.us-east-2.amazonaws.com/glazed.png', 0.0),
(2, 'Chocolate Iced Glazed Doughnut', 'Glazed', 'https://donutsbucket.s3.us-east-2.amazonaws.com/choco-glazed.png', 0.0),
(3, 'Raspberry Filled Doughnut', 'Filled', 'https://donutsbucket.s3.us-east-2.amazonaws.com/rasp-filled-glazed.png', 0.0),
(4, 'Glazed Blueberry Cake Doughnut', 'Glazed', 'https://donutsbucket.s3.us-east-2.amazonaws.com/blueberry-cake-glazed.png', 0.0),
(5, 'Strawberry Iced Doughnut with Sprinkles', 'Iced', 'https://donutsbucket.s3.us-east-2.amazonaws.com/strawberry-sprinkles-iced.png', 0.0),
(6, 'Lemon Filled Doughnut', 'Filled', 'https://donutsbucket.s3.us-east-2.amazonaws.com/lemon-filled-glazed.png', 0.0),
(7, 'Chocolate Iced Custard Filled Doughnut', 'Filled', 'https://donutsbucket.s3.us-east-2.amazonaws.com/choco-filled-iced.png', 0.0);
