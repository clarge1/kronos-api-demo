from discord import Webhook
import aiohttp
import asyncio
import platform

if platform.system()=='Windows':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

async def foo(message):
    async with aiohttp.ClientSession() as session:
        webhook = Webhook.from_url('https://discord.com/api/webhooks/1186034030123167784/ufNmlvx8D6dV1c5qZYpild0BP6-aIqViS8kPeeHX-pqHvYXTQEr1DPzMzFPXJmpJv4NT', session=session)
        await webhook.send(message, username='Kronos')

def send_message(message):
    print(f'Sending message to Discord: {message}')
    asyncio.run(foo(message))
