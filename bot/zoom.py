from typing import Optional
import json
import aiohttp
import jwt
import time
from datetime import datetime, timedelta

class ZoomMeeting:
    def __init__(self, account_id: str, client_id: str, client_secret: str):
        self.account_id = account_id
        self.client_id = client_id
        self.client_secret = client_secret
        self.base_url = "https://api.zoom.us/v2"

    def _generate_token(self) -> str:
        """Generate a JWT token for Server-to-Server OAuth"""
        token = jwt.encode(
            {
                "aud": None,
                "iss": self.client_id,
                "exp": int(time.time() + 3600),  # Token expires in 1 hour
                "iat": int(time.time())
            },
            self.client_secret,
            algorithm="HS256",
            headers={
                "alg": "HS256",
                "typ": "JWT"
            }
        )
        return token

    async def create_meeting(
        self,
        topic: str,
        start_time: datetime,
        duration: int,
        timezone: str = "Asia/Tashkent"
    ) -> Optional[dict]:
        """Create a Zoom meeting and return meeting details"""
        try:
            token = self._generate_token()
            
            # Prepare meeting data
            meeting_data = {
                "topic": topic,
                "type": 2,  # Scheduled meeting
                "start_time": start_time.strftime("%Y-%m-%dT%H:%M:%S"),
                "duration": duration,
                "timezone": timezone,
                "settings": {
                    "host_video": True,
                    "participant_video": True,
                    "join_before_host": True,
                    "mute_upon_entry": False,
                    "waiting_room": False,
                    "auto_recording": "none",
                    "use_pmi": False,  # Don't use Personal Meeting ID
                    "approval_type": 0,  # Automatically approve
                    "registration_type": 1,  # Attendees register once and can attend any occurrence
                    "audio": "both",  # Both telephony and VoIP
                    "alternative_hosts": "",  # No alternative hosts
                    "close_registration": False,  # Registration remains open
                    "registrants_email_notification": True  # Send email notifications to registrants
                }
            }
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/users/me/meetings",
                    json=meeting_data,
                    headers=headers
                ) as response:
                    if response.status == 201:
                        result = await response.json()
                        return {
                            "id": result.get("id"),
                            "join_url": result.get("join_url"),
                            "password": result.get("password"),
                            "start_url": result.get("start_url")
                        }
                    print(f"Error creating meeting: {await response.text()}")
                    return None
        except Exception as e:
            print(f"Error creating Zoom meeting: {e}")
            return None

    async def delete_meeting(self, meeting_id: str) -> bool:
        """Delete a Zoom meeting"""
        try:
            token = self._generate_token()
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.delete(
                    f"{self.base_url}/meetings/{meeting_id}",
                    headers=headers
                ) as response:
                    return response.status == 204
        except Exception as e:
            print(f"Error deleting Zoom meeting: {e}")
            return False

    async def update_meeting(
        self,
        meeting_id: str,
        topic: Optional[str] = None,
        start_time: Optional[datetime] = None,
        duration: Optional[int] = None,
        timezone: Optional[str] = None
    ) -> bool:
        """Update an existing Zoom meeting"""
        try:
            token = self._generate_token()
            
            # Prepare update data
            update_data = {}
            if topic:
                update_data["topic"] = topic
            if start_time:
                update_data["start_time"] = start_time.strftime("%Y-%m-%dT%H:%M:%S")
            if duration:
                update_data["duration"] = duration
            if timezone:
                update_data["timezone"] = timezone
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.patch(
                    f"{self.base_url}/meetings/{meeting_id}",
                    json=update_data,
                    headers=headers
                ) as response:
                    return response.status == 204
        except Exception as e:
            print(f"Error updating Zoom meeting: {e}")
            return False