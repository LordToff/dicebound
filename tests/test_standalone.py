"""Current standalone browser regression suite (compatibility entry point)."""
import asyncio
from test_browser_v1 import main

if __name__ == '__main__':
    asyncio.run(main())
