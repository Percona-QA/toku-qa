#!/usr/bin/env python 

import base64
import requests
from dateutil import parser
import datetime as dt
import smtplib
import datetime
from twilio.rest import TwilioRestClient


def usage():
    print "monitor freshdesk for urgent cases"
    return 1

def sendGmail(username, password, recipient, subject, message):
    session = smtplib.SMTP('smtp.gmail.com', 587)
    session.ehlo()
    session.starttls()
    session.login(username, password)

    headers = "\r\n".join(["from: " + username,
                           "subject: " + subject,
                           "to: " + recipient,
                           "mime-version: 1.0",
                           "content-type: text/html"])

    content = headers + "\r\n\r\n" + message
    session.sendmail(username, recipient, content)


def callPhoneViaTwilio(twilioAccountSid, twilioAuthToken, twilioToPhoneNumbers, twilioFromPhoneNumber):
    callMessage="Urgent%20Freshdesk%20Urgent%20Freshdesk%20Urgent%20Freshdesk%20Urgent%20Freshdesk%20Urgent%20Freshdesk%20Urgent%20Freshdesk"
    client = TwilioRestClient(twilioAccountSid,twilioAuthToken)
    for toNumber in twilioToPhoneNumbers:
        print "called: ", toNumber
        call = client.calls.create(to=toNumber,
                                   from_=twilioFromPhoneNumber,
                                   url="http://twimlets.com/message?Message%5B0%5D="+callMessage+"&")



fdApiUser='2L0hmyQKHFVNlqHG12J'
fdApiPass='X'
fdApiBaseURL='http://tokutek.freshdesk.com'
fdApiTicketURL='/helpdesk/tickets/view/316984?format=json'
gmailUsername='tim@tokutek.com'
gmailPassword='<NOT-HAPPENING>'

twilioFromPhoneNumber='+13392938419'
lexSupport='+17816989206'
nycSupport='+17816986155'
leifCell='+12282734565'
zardoshtCell='+16178996353'
joelCell='+16178771636'
abdelhakCell='+16173314869'

twilioToPhoneNumbers=[leifCell,nycSupport,abdelhakCell]

twilioAccountSid='AC3f87a6aef95fb6dc1703a91546c7654a'
twilioAuthToken='f38ab99b6b044788fab9a48192fb553e'


print datetime.datetime.now()

response = requests.get(fdApiBaseURL + fdApiTicketURL, auth=(fdApiUser, fdApiPass))
if response.status_code != 200: 
    print('Status:', response.status_code, 'Problem with the request : TICKETS. Exiting.')
    exit()
data = response.json()

#print data
for ticket in data:
    ticketPriority = ticket['priority']
    if ticketPriority == 1:
        ticketPriorityString = 'low'
    elif ticketPriority == 2:
        ticketPriorityString = 'medium'
    elif ticketPriority == 3:
        ticketPriorityString = 'high'
    else:
        ticketPriorityString = 'urgent'
        
    ticketCreatedAt = parser.parse(ticket['created_at'])
    ticketMinutesOld = ((dt.datetime.now(parser.tz.tzlocal()) - ticketCreatedAt).seconds / 60)

    contactResponse = requests.get(fdApiBaseURL + '/contacts/' + str(ticket['requester_id']) + '.json', auth=(fdApiUser, fdApiPass))
    if contactResponse.status_code != 200: 
        print('Status:', contactResponse.status_code, 'Problem with the request : CONTACTS ' + str(ticket['requester_id']) + ', exiting.')
        exit()
    contactData = contactResponse.json()

    if contactData['user']['customer_id'] != None:
        # might need to page, the issue's user is part of a customer
        customerResponse = requests.get(fdApiBaseURL + '/customers/' + str(contactData['user']['customer_id']) + '.json', auth=(fdApiUser, fdApiPass))
        if customerResponse.status_code != 200: 
            print('Status:', customerResponse.status_code, 'Problem with the request : CUSTOMERS ' + str(contactData['user']['customer_id']) + ', exiting.')
            exit()
        customerData = customerResponse.json()

        sendPage = False
        
        # determine the SLA
        customerSLA = 'None'
        customerName = customerData['customer']['name']
        customerNote = customerData['customer']['note']
        if "sla=7x24" in customerNote:
            customerSLA = "24x7"
        elif "sla=5x12" in customerNote:
            customerSLA = "12x5"
        elif "sla=5x8" in customerNote:
            customerSLA = "8x5"
        else:
            customerSLA = "None"
            
        ticketHour = ticketCreatedAt.hour
        ticketWeekday = ticketCreatedAt.weekday()
            
        if ticketPriorityString == 'urgent':
        #if (ticketPriorityString == 'low') or (ticketPriorityString == 'medium') or (ticketPriorityString == 'high') or (ticketPriorityString == 'urgent'):
            if customerSLA == '24x7':
                sendPage = True
            elif customerSLA == '12x5':
                if (ticketHour >= 8 and ticketHour < 20) and (ticketWeekday >= 0 and ticketWeekday <= 4):
                    sendPage = True
            elif customerSLA == '8x5':
                if (ticketHour >= 8 and ticketHour < 17) and (ticketWeekday >= 0 and ticketWeekday <= 4):
                    sendPage = True
            
        # check time of day to determine if paging is necessary
        if sendPage:
            print str(ticket['display_id']), "| created:", ticket['created_at'], "| minutes: ", ticketMinutesOld, "| priority: ", ticketPriorityString, "| contact: ", contactData['user']['name'], "| company: " , customerData['customer']['name'].encode('utf-8'), "| sla: " , customerSLA, "| PAGING!!!"
            #sendGmail(gmailUsername, gmailPassword, '6179574237@message.ting.com', 'FD Alert : ' + str(ticket['display_id']), 'FD Alert : ' + str(ticket['display_id']))
            #sendGmail(gmailUsername, gmailPassword, '7816989206@message.ting.com', 'FD Alert : ' + str(ticket['display_id']), 'FD Alert : ' + str(ticket['display_id']))
            callPhoneViaTwilio(twilioAccountSid, twilioAuthToken, twilioToPhoneNumbers, twilioFromPhoneNumber)
        else:
            print str(ticket['display_id']), "| created:", ticket['created_at'], "| minutes: ", ticketMinutesOld, "| priority: ", ticketPriorityString, "| contact: ", contactData['user']['name'], "| company: " , customerData['customer']['name'].encode('utf-8'), "| sla: " , customerSLA, "| NO PAGE, OUTSIDE OF SLA"
    
    else:
        # user is not connected to a company, just output for debugging purposes
        print str(ticket['display_id']), "| created:", ticket['created_at'], "| minutes: ", ticketMinutesOld, "| priority: ", ticketPriorityString, "| contact: ", contactData['user']['name'].encode('utf-8'), "| NO COMPANY, NO PAGE"
