import pytz
from datetime import datetime, timedelta



def get_local_timestamp():
    CST = pytz.timezone("US/Central")
    now_cst = datetime.now(CST)
    return now_cst.strftime("%Y-%m-%d %I:%M:%S%p")

def get_next_unlock_time():
    CST = pytz.timezone("US/Central")
    now_cst = datetime.now(CST)
    now_tmp = now_cst
    now_tmp = now_tmp + timedelta( seconds=60-now_tmp.second )
    next_minute = now_tmp
    print(next_minute.strftime("%I:%M:%S%p"))
    now_tmp = now_tmp - timedelta( minutes=20 )
    now_tmp = now_tmp - timedelta( hours=16 )
    now_tmp = now_tmp + timedelta( days=(3-now_tmp.weekday()) % 7 +1)
    next_unlock = now_tmp.replace(hour=16,minute=20,second=0)
    print(next_unlock.strftime("%Y-%m-%d %I:%M:%S%p"))

    diff = next_unlock - next_minute
    total_minutes = diff.total_seconds() / 60
    days = total_minutes // (60*24)
    remainder = total_minutes % (60*24)
    hours = remainder // (60)
    minutes = remainder % (60)

    print('Total difference in minutes: ', total_minutes)
    print(f'Days: {int(days)} , Hours: {int(hours)} , Minutes: {int(minutes)}')

    return f'Next unlock is {next_unlock.strftime("%Y-%m-%d %I:%M%p")}\n\
Today at {next_minute.strftime("%I:%M:%S%p")}, time remaining is:\n\
Days: {int(days)} , Hours: {int(hours)} , Minutes: {int(minutes)}'

if __name__ == '__main__':
    # Do nothing if executed as a script
    print(get_next_unlock_time())
