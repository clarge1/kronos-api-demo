from discord import Webhook
import aiohttp

async def foo():
    async with aiohttp.ClientSession() as session:
        webhook = Webhook.from_url('https://discord.com/api/webhooks/1186034030123167784/ufNmlvx8D6dV1c5qZYpild0BP6-aIqViS8kPeeHX-pqHvYXTQEr1DPzMzFPXJmpJv4NT', session=session)
        await webhook.send('Hello World', username='Foo')
