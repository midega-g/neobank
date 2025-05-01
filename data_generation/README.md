# About the Data

This module, `customer_data_generator.py`, is responsible for generating synthetic customer data for use in testing,
development, or simulation environments. The data generation process is designed to create some sort of realistic and diverse
customer profiles while maintaining flexibility for customization.

Key Functionalities:

1. **Randomized Customer Profile Generation**:
    - The generator creates customer profiles with attributes such as name, age, email, phone number, address, and
      purchase history.
    - Names are generated using a combination of predefined first and last name lists or external libraries like `Faker` for
      realistic results.
    - Age is randomly assigned within a specified range to simulate a diverse customer base.

2. **Email and Phone Number Formatting**:
    - Email addresses are dynamically generated using the customer's name and a random domain from a predefined list.
    - Phone numbers are formatted according to a specific pattern, ensuring consistency and validity.

3. **Address Generation**:
    - Addresses are created using a combination of random street names, numbers, cities, states, and postal codes.
    - The generator may include support for multiple countries, allowing for international address formats.

4. **Purchase History Simulation**:
    - The generator simulates a purchase history for each customer, including product names, quantities, prices, and
      purchase dates.
    - Purchase dates are randomized within a specified time range to reflect realistic shopping behavior.

5. **Customizability**:
    - The generator allows for customization of parameters such as the number of customers to generate, age range,
      geographic region, and purchase history depth.
    - Users can specify seed values for reproducibility of the generated data.

6. **Data Export**:
    - The generated customer data is exported to CSV formats into different folders to simulate different sources such as
      Account Management System (AMS), Customer Relationship Management (CRM), and Transaction Processing System (TPS).

This script is particularly useful if you need to generate the same customer data based on your specification in terms of data size. Moreover, the generated data is entirely synthetic and does not contain any real customer information, ensuring compliance with privacy regulations.
