#!/usr/bin/env python 

import base64
import requests
from dateutil import parser
import datetime as dt
import smtplib
import datetime

fdApiUser='2L0hmyQKHFVNlqHG12J'
fdApiPass='X'
fdApiBaseURL='http://tokutek.freshdesk.com'
fdApiCustomerURL='/customers.json?page='

pageNum=1
apiCallEmpty=False
slaCustomers=[]

# Get the list of customers with SLAs from FD
while not apiCallEmpty:
    response = requests.get(fdApiBaseURL + fdApiCustomerURL + str(pageNum), auth=(fdApiUser, fdApiPass))
    if response.status_code != 200: 
        print('Status:', response.status_code, 'Problem with the request : TICKETS. Exiting.')
        exit()
    data = response.json()

    if len(data) == 0:
        apiCallEmpty = True
    else:
        for customer in data:
            customerName = customer['customer']['name'].encode('utf-8')
            customerNote = None
            if customer['customer']['note']:
                customerNote = customer['customer']['note'].encode('utf-8')
                #print customerName + " | " + customerNote
                slaCustomers.append(customerNote + " | " + customerName)
                
    
    pageNum += 1


# Print out the list
slaCustomers.sort()
for customer in slaCustomers:
    print customer

