from __future__ import annotations
import json
import pathlib
from urllib.parse import urlparse
from typing import Optional


def transform_ror(ror_path: pathlib.Path, output_path: pathlib.Path):
    results = []

    # Load ROR
    with open(ror_path) as f:
        data = json.load(f)

    # Transform ROR
    for record in data:
        # Skip the inactive records
        if not is_active(record):
            continue

        results.append(
            dict(
                uri=record.get("id"),
                provenance="ROR",
                name=get_name(record),
                displayName=get_display_name(record),
                searchName=get_search_name(record),
                funder=get_is_funder(record),
                fundrefId=get_fundref_id(record),
                homepage=get_homepage(record),
                domain=get_domain(record),
                acronyms=get_acronyms(record),
                aliases=get_aliases(record),
                types=get_types(record),
            )
        )

    # Save ROR
    with open(output_path, mode="w") as f:
        json.dump(results, f)


def is_active(record: dict) -> bool:
    return record.get("status") == "active"

def get_name(record: dict) -> Optional[str]:
    for name in record.get("names", []):
        if "ror_display" in name.get("types", []):
            return name.get("value")


def get_acronyms(record: dict) -> list[str]:
    values = []
    for name in record.get("names", []):
        if "acronym" in name.get("types", []):
            values.append(name.get("value"))
    return values


def get_aliases(record: dict) -> list[str]:
    values = []
    for name in record.get("names", []):
        if "alias" in name.get("types", []):
            values.append(name.get("value"))
    return values


def get_domain(record: dict) -> Optional[str]:
    domains = record.get("domains", [])
    if domains:
        return domains[0]

    # If no domain was defined in the ROR record, extract it from the homepage
    return extract_domain_from_homepage(get_homepage(record) or "")

def extract_domain_from_homepage(homepage: str) -> str | None:
    if not homepage:
        return None

    parsed = urlparse(homepage)
    hostname = parsed.hostname or ""
    if not hostname:
        return None

    # Remove "www." only if it's the leading subdomain
    if hostname.startswith("www."):
        hostname = hostname[4:]

    return hostname

def get_display_name(record: dict) -> str:
    name = get_name(record)
    domain = get_domain(record)
    parts = []

    if name is not None:
        parts.append(name)

    if domain:
        parts.append(f"({domain})")

    return " ".join(parts)

def get_search_name(record: dict) -> str:
    name = get_name(record)
    domain = get_domain(record)
    aliases = get_aliases(record)
    parts = []

    if name is not None:
        parts.append(name)

    if domain:
        parts.append(domain)

    if aliases:
        parts.extend(aliases)

    return " | ".join(parts)


def get_is_funder(record: dict) -> bool:
    return "funder" in record.get("types", [])


def get_fundref_id(record: dict) -> Optional[str]:
    for data in record.get("external_ids"):
        if data.get("type") == "fundref":
            return data.get("preferred")


def get_homepage(record: dict) -> Optional[str]:
    for link in record.get("links"):
        if link.get("type") == "website":
            return link.get("value")


def get_types(record: dict):
    return [type.upper() for type in record.get("types")]


if __name__ == "__main__":
    transform_ror(
        pathlib.Path("./data/v1.71-2025-09-22-ror-data_schema_v2.json"),
        pathlib.Path("./data/affiliations.json"),
    )
