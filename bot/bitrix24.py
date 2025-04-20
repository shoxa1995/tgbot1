from typing import Optional
import aiohttp
from datetime import datetime

class Bitrix24Calendar:
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url
        self.base_url = f"{webhook_url}/calendar.event"

    async def create_event(
        self,
        title: str,
        description: str,
        start_date: datetime,
        end_date: datetime,
        attendees: list[str]
    ) -> Optional[str]:
        """Create a calendar event in Bitrix24"""
        try:
            event_data = {
                "type": "user",
                "ownerId": "1",  # Default owner ID
                "name": title,
                "description": description,
                "from": start_date.strftime("%Y-%m-%dT%H:%M:%S%z"),
                "to": end_date.strftime("%Y-%m-%dT%H:%M:%S%z"),
                "skipTime": "N",
                "attendees": attendees,
                "color": "#9dcf00",  # Green color for events
                "accessibility": "busy",
                "importance": "normal",
                "private_event": "N",
                "remind": [
                    {
                        "type": "min",
                        "count": "15"
                    }
                ]
            }

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}.add",
                    json={"fields": event_data}
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result.get("result", {}).get("id")
                    print(f"Error creating Bitrix24 event: {await response.text()}")
                    return None
        except Exception as e:
            print(f"Error creating Bitrix24 event: {e}")
            return None

    async def update_event(
        self,
        event_id: str,
        title: Optional[str] = None,
        description: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        attendees: Optional[list[str]] = None
    ) -> bool:
        """Update an existing calendar event in Bitrix24"""
        try:
            update_data = {}
            if title:
                update_data["name"] = title
            if description:
                update_data["description"] = description
            if start_date:
                update_data["from"] = start_date.strftime("%Y-%m-%dT%H:%M:%S%z")
            if end_date:
                update_data["to"] = end_date.strftime("%Y-%m-%dT%H:%M:%S%z")
            if attendees:
                update_data["attendees"] = attendees

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}.update",
                    json={
                        "id": event_id,
                        "fields": update_data
                    }
                ) as response:
                    return response.status == 200
        except Exception as e:
            print(f"Error updating Bitrix24 event: {e}")
            return False

    async def delete_event(self, event_id: str) -> bool:
        """Delete a calendar event from Bitrix24"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}.delete",
                    json={"id": event_id}
                ) as response:
                    return response.status == 200
        except Exception as e:
            print(f"Error deleting Bitrix24 event: {e}")
            return False