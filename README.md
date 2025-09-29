# DMP Tool Migration

SQLMesh project to facilitate data migration from the old Rails/ActiveRecord based DMP Tool system to the new Node Apollo server system.

## Overview

This project uses SQLMesh to orchestrate the migration of data from the legacy Rails-based DMP Tool to the new Node.js Apollo GraphQL server system. The migration includes:

- **Users**: User accounts and profiles
- **Plans**: Data Management Plans (DMPs)
- **Organizations**: Institutional affiliations
- **Templates**: DMP templates and structures

## Project Structure

```
├── config.py              # SQLMesh configuration
├── migrate.py             # Main migration script
├── .env.example           # Environment variables template
├── models/                # SQLMesh data models
│   ├── source_users.sql   # Extract users from Rails system
│   ├── source_plans.sql   # Extract plans from Rails system
│   ├── target_users.sql   # Transform users for Apollo format
│   └── target_plans.sql   # Transform plans for Apollo format
├── audits/                # Data quality audits
│   ├── users_email_validation.sql
│   └── plans_title_validation.sql
├── tests/                 # Unit tests
│   └── test_target_users.yaml
└── seeds/                 # Sample data for testing
    ├── users.csv
    └── plans.csv
```

## Quick Start

1. **Install dependencies**:
   ```bash
   pip install sqlmesh
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your database connections
   ```

3. **Run the migration**:
   ```bash
   python migrate.py
   ```

## SQLMesh Commands

- **Plan migration**: `sqlmesh plan dev`
- **Run tests**: `sqlmesh test`
- **Run audits**: `sqlmesh audit`
- **Check project**: `sqlmesh info`
- **Start UI**: `sqlmesh ui`

## Data Flow

1. **Extract**: Source models read data from the legacy Rails system
2. **Transform**: Target models convert data to Apollo GraphQL format
3. **Validate**: Audits ensure data quality and completeness
4. **Test**: Unit tests verify transformations work correctly

## Configuration

The project uses DuckDB as the processing engine, which allows for:
- Efficient data processing without requiring a separate database
- Easy integration with both PostgreSQL sources and targets
- Support for CSV files during development and testing

## Environment Variables

See `.env.example` for required configuration:
- Source database connection (Rails system)
- Target database connection (Apollo system)
- DuckDB local database path
- Migration batch size and logging settings

## Development

To add new models or modify existing ones:

1. Create/edit SQL files in the `models/` directory
2. Add corresponding tests in the `tests/` directory
3. Add data quality audits in the `audits/` directory
4. Test your changes with `sqlmesh plan dev`

## Production Deployment

For production migrations:

1. Set environment to `prod`: `sqlmesh plan prod`
2. Review the migration plan carefully
3. Apply with: `sqlmesh apply`
4. Monitor with: `sqlmesh audit` and `sqlmesh test`
