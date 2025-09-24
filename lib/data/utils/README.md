# Utils

This directory contains utility functions and helper classes used throughout the data layer of the Omada Contacts app.

## Files

- `query_utils.dart` - Utilities for building and managing database queries
- `validation_utils.dart` - Functions for data validation
- `utils.dart` - Barrel file that exports all utilities

## Usage

These utilities provide common functionality that is used across different parts of the data layer:

- Query building and optimization
- Data validation and sanitization
- Common helper functions

Utilities are designed to be stateless and focus on specific, reusable functionality that doesn't belong in any specific model, repository, or service.