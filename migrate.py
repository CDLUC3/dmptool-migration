#!/usr/bin/env python3
"""
Migration script for DMP Tool data migration using SQLMesh.

This script orchestrates the migration process from the old Rails/ActiveRecord
DMP Tool system to the new Node Apollo server system.
"""

import os
import sys
import logging
from pathlib import Path
from sqlmesh import Context

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def run_migration():
    """
    Run the complete migration process.
    """
    try:
        # Initialize SQLMesh context
        logger.info("Initializing SQLMesh context...")
        context = Context()
        
        # Plan the migration
        logger.info("Planning migration...")
        plan = context.plan("dev", auto_apply=False)
        
        if plan.requires_backfill:
            logger.info("Migration requires backfill. Applying plan...")
            context.apply(plan)
        else:
            logger.info("No backfill required. Migration is up to date.")
        
        # Run audits
        logger.info("Running data quality audits...")
        audit_results = context.audit()
        
        if audit_results:
            logger.warning(f"Found {len(audit_results)} audit issues")
            for result in audit_results:
                logger.warning(f"Audit '{result.name}': {result.count} issues found")
        else:
            logger.info("All audits passed successfully")
        
        # Run tests
        logger.info("Running tests...")
        test_results = context.test()
        
        if test_results.failures:
            logger.error(f"Found {len(test_results.failures)} test failures")
            for failure in test_results.failures:
                logger.error(f"Test '{failure}' failed")
            return False
        else:
            logger.info("All tests passed successfully")
        
        logger.info("Migration completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Migration failed: {str(e)}")
        return False

def main():
    """
    Main entry point for the migration script.
    """
    logger.info("Starting DMP Tool migration...")
    
    success = run_migration()
    
    if success:
        logger.info("Migration completed successfully!")
        sys.exit(0)
    else:
        logger.error("Migration failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()