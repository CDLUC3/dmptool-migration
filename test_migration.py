#!/usr/bin/env python3
"""
SQLMesh Migration Test Script

This script tests the complete migration pipeline by running all models
and validating the output.
"""

import sys
import pandas as pd
from sqlmesh import Context

def main():
    """Test the complete migration pipeline."""
    print("🚀 Testing DMP Tool Migration Pipeline")
    print("=" * 50)
    
    try:
        # Initialize SQLMesh context
        context = Context()
        
        # Test all source models
        print("\n📊 Testing Source Models:")
        
        print("  - Testing source_users...")
        users_df = context.fetchdf("SELECT * FROM source_users")
        print(f"    ✓ Extracted {len(users_df)} users")
        
        print("  - Testing source_plans...")
        plans_df = context.fetchdf("SELECT * FROM source_plans")
        print(f"    ✓ Extracted {len(plans_df)} plans")
        
        print("  - Testing source_organizations...")
        orgs_df = context.fetchdf("SELECT * FROM source_organizations")
        print(f"    ✓ Extracted {len(orgs_df)} organizations")
        
        # Test all target models
        print("\n🎯 Testing Target Models:")
        
        print("  - Testing target_users...")
        target_users_df = context.fetchdf("SELECT * FROM target_users")
        print(f"    ✓ Transformed {len(target_users_df)} users")
        print(f"    ✓ Sample Apollo ID: {target_users_df.iloc[0]['apollo_id']}")
        
        print("  - Testing target_plans...")
        target_plans_df = context.fetchdf("SELECT * FROM target_plans")
        print(f"    ✓ Transformed {len(target_plans_df)} plans")
        print(f"    ✓ Sample Apollo ID: {target_plans_df.iloc[0]['apollo_id']}")
        
        print("  - Testing target_organizations...")
        target_orgs_df = context.fetchdf("SELECT * FROM target_organizations")
        print(f"    ✓ Transformed {len(target_orgs_df)} organizations")
        print(f"    ✓ Sample Apollo ID: {target_orgs_df.iloc[0]['apollo_id']}")
        
        # Test data consistency
        print("\n🔍 Validating Data Consistency:")
        
        # Check that no data was lost in transformation
        assert len(users_df) == len(target_users_df), "User count mismatch"
        assert len(plans_df) == len(target_plans_df), "Plans count mismatch"
        assert len(orgs_df) == len(target_orgs_df), "Organizations count mismatch"
        print("    ✓ No data loss during transformation")
        
        # Check that Apollo IDs are properly formatted
        apollo_ids = target_users_df['apollo_id'].tolist()
        assert all(id.startswith('user_') for id in apollo_ids), "Invalid user Apollo IDs"
        print("    ✓ Apollo IDs properly formatted")
        
        # Show summary statistics
        print("\n📈 Migration Summary:")
        print(f"  • Users migrated: {len(target_users_df)}")
        print(f"  • Plans migrated: {len(target_plans_df)}")
        print(f"  • Organizations migrated: {len(target_orgs_df)}")
        print(f"  • Total records: {len(target_users_df) + len(target_plans_df) + len(target_orgs_df)}")
        
        print(f"\n✅ Migration pipeline test completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Migration test failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()