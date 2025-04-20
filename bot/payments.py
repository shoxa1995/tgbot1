from typing import Optional
import hashlib
import json
import aiohttp
from datetime import datetime
from aiogram.types import LabeledPrice, PreCheckoutQuery

class ClickUzPayment:
    def __init__(self):
        self.live_token = "333605228:LIVE:18486_1A5B4FF440980100E5F5C1D745DFCB165C5E2A37"
        self.test_token = "398062629:TEST:999999999_F91D8F69C042267444B74CC0B3C747757EB0E065"
        self.is_test = False  # Set to True to use test token

    @property
    def token(self) -> str:
        """Get the appropriate token based on test mode"""
        return self.test_token if self.is_test else self.live_token

    async def create_invoice(self, chat_id: int, title: str, description: str, amount: int, payload: str) -> bool:
        """Create a payment invoice using Telegram Payments API"""
        try:
            prices = [LabeledPrice(label=title, amount=amount * 100)]  # Amount in cents
            
            bot_data = {
                "chat_id": chat_id,
                "title": title,
                "description": description,
                "payload": payload,
                "provider_token": self.token,
                "currency": "UZS",
                "prices": prices,
                "start_parameter": "booking_payment"
            }
            
            return bot_data
        except Exception as e:
            print(f"Error creating Click.uz payment invoice: {e}")
            return None

    async def verify_payment(self, pre_checkout_query: PreCheckoutQuery) -> bool:
        """Verify pre-checkout query"""
        try:
            # Here you can add additional verification logic if needed
            return True
        except Exception as e:
            print(f"Error verifying Click.uz payment: {e}")
            return False

    def set_test_mode(self, enabled: bool = True):
        """Enable or disable test mode"""
        self.is_test = enabled