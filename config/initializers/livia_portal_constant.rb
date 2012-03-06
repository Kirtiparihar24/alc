# To change this template, choose Tools | Templates
# and open the template in the editor.

#puts "Hello World"

# change the version of the livia_portal
LIVIA_PORTAL_VERSION='3.5.0.0'

# this Reqular Expression is used for Opportunity, matter, account, contact realted filter search
FILTTER_PATTERN = /(\'|\"|\?|\:|\{|\}|\~|\<|\>|\;|\!|\^|\(|\)|\[|\&|\$|\]|\*|\/|\#|\%|\\)/
# this Reqular Expression is used for matter realted filter search It allows ampersand in filter search
AMPERSAND_FILTTER_PATTERN = /(\'|\"|\?|\:|\{|\}|\~|\<|\>|\;|\!|\^|\(|\)|\[|\$|\]|\*|\/|\#|\%|\\)/

#This Regular Expression is used for matter Inception date is handle in this pattern for filter search
MATTER_FILTTER_PATTERN = /(\'|\"|\?|\:|\{|\}|\~|\<|\>|\;|\!|\^|\(|\)|\[|\&|\$|\]|\*|\#|\%|\\)/