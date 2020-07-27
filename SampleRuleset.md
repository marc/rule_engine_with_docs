# Ruleset Documentation

## Rules
contact_info1 - No Contact Information Provided

name_length_fl - Maximum Name Length (FL)

simple_rule01 - 



## Fields
### email
contact_info1


### name
name_length_fl


### phone
contact_info1


### team_chat_user_name
contact_info1




## Tags
### contact_info
contact_info1


### florida
name_length_fl


### maximum_length
name_length_fl


### single_field
name_length_fl




## Types
### error 
name_length_fl


### notice
contact_info1


### undefined
simple_rule01




## Rule Descriptions
### contact_info1
Name: No Contact Information Provided

Type: notice

Fields: email, phone, team_chat_user_name

Tags: contact_info

Message: "No contact information provided. If you wish to receive updates, please provide at least one of the following: email, phone, team_chat_user_name"

#### Description


### name_length_fl
Name: Maximum Name Length (FL)

Type: error

Fields: name

Tags: maximum_length, single_field, florida

Message: "Sample 1 name should be at most #{50 + 50} characters in length in Florida." 

#### Description
This rule is only active in Florida.
The Sample 1 name has a maximum length of 100 characters.


### simple_rule01
Name: 

Type: undefined

Fields: 

Tags: 

Message: nil

#### Description
A simple rule example.

