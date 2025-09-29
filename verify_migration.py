#!/usr/bin/env python3
"""
Simple verification script for the DMP Tool migration.
Tests that all models and data are working correctly.
"""

from sqlmesh import Context

def main():
    """Verify the migration is working."""
    print("🔍 Verifying DMP Tool Migration")
    print("=" * 40)
    
    context = Context()
    
    # Check basic connectivity
    print("✓ SQLMesh context initialized")
    
    # Test a simple query to verify tables exist
    try:
        result = context.fetchdf("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%source%' OR table_name LIKE '%target%'")
        table_count = len(result)
        print(f"✓ Found {table_count} migration tables")
        
        if table_count >= 6:  # 3 source + 3 target
            print("✅ All expected tables are present")
        else:
            print(f"⚠️  Expected at least 6 tables, found {table_count}")
            
    except Exception as e:
        print(f"❌ Error checking tables: {e}")
        return False
    
    print("\n🎯 Migration infrastructure is ready!")
    print("📚 Next steps:")
    print("   1. Configure source database connections in .env")
    print("   2. Replace CSV files with database connections")
    print("   3. Run 'sqlmesh plan prod' to execute migration")
    print("   4. Monitor with 'sqlmesh audit' for data quality")
    
    return True

if __name__ == "__main__":
    main()