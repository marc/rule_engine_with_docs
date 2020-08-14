# Ruleset Documentation

## Rules
age_check_18 - Age Check 18+

contact_info_req - No Contact Information Provided

first_name_length_fl - Maximum First Name Length (FL)

guardian_for_minor - Guardian Name Required for Minors

simple_rule01 - 

test_data_detector - No Test Data Allowed



## Fields
### date_of_birth
age_check_18

guardian_for_minor


### email
contact_info_req


### first_name
first_name_length_fl

test_data_detector


### guardian_name
guardian_for_minor

test_data_detector


### last_name
test_data_detector


### phone
contact_info_req




## Tags
### contact_info
contact_info_req


### correlation
guardian_for_minor


### florida
first_name_length_fl


### maximum_length
first_name_length_fl


### missing_data
contact_info_req

guardian_for_minor


### single_field
age_check_18

first_name_length_fl


### test_data
test_data_detector




## Types
### error
contact_info_req

guardian_for_minor

test_data_detector


### notice 
age_check_18

first_name_length_fl


### undefined
simple_rule01




## Rule Descriptions
### age_check_18
Name: Age Check 18+

Type: notice

Fields: date_of_birth

Tags: single_field

Message: "This person is a minor based on today's date and the submitted date of birth (#{data[:registration][:date_of_birth]})."

#### Description
If a date of birth is submitted, check if the person is 18+ as of today.
This rule does not apply if no valid ISO 8601 date (YYYY-MM-DD) was submitted.

Technical Note: Using Date.diff to check the number of days between the date of birth and today.


### contact_info_req
Name: No Contact Information Provided

Type: error

Fields: email, phone

Tags: contact_info, missing_data

Message: "No contact information provided. One of the following contact information fields is required: email, phone"

#### Description


### first_name_length_fl
Name: Maximum First Name Length (FL)

Type: notice

Fields: first_name

Tags: maximum_length, single_field, florida

Message: "First name should be at most #{50 + 50} characters in length in Florida."

#### Description
This sample rule is only active in Florida.
The first name has a maximum length of 100 characters.


### guardian_for_minor
Name: Guardian Name Required for Minors

Type: error

Fields: date_of_birth, guardian_name

Tags: correlation, missing_data

Message: "The guardian name is required if the registration is submitted for a minor."

#### Description
If a date of birth is submitted in ISO 8601 format (YYYY-MM-DD), check if the person is 18+ as of today to determine if they are a minor.
The guardian name is required if the registration is submitted for a minor.


### simple_rule01
Name: 

Type: undefined

Fields: 

Tags: 

Message: nil

#### Description
A simple rule example.

### test_data_detector
Name: No Test Data Allowed

Type: error

Fields: first_name, guardian_name, last_name

Tags: test_data

Message: "Test data detected in one of the following fields: first_name, guardian_name, last_name."

#### Description
Do not allow the word 'test' (case insensitive) in the first name, last name or guardian name.

