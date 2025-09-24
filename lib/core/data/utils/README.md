# Utils

This directory contains utility functions and helper classes used throughout the data layer of the Omada Contacts app.

## Files

- `query_utils.dart` - Utilities for building and managing database queries
- `validation_utils.dart` - Functions for data validation
- `channel_launcher.dart` - Deep-link launcher with app-first and web fallbacks
- `channel_presets.dart` - Preset kinds and URL computation for channels
- `utils.dart` - Barrel file that exports all utilities

## Usage

These utilities provide common functionality that is used across different parts of the data layer:

- Query building and optimization
- Data validation and sanitization
- Deep link construction and launching for contact channels
- Preset-based URL generation for add-channel workflows
- Common helper functions

Utilities are designed to be stateless and focus on specific, reusable functionality that doesn't belong in any specific model, repository, or service. The `channel_launcher.dart` and `channel_presets.dart` utilities support Epic 3 (Contact Channels) features and are used by `AddChannelSheet` and the profile page channel actions.