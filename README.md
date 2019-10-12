# Ruby Macy's parser
Scrapes products (clothes and shoes) from macys.com. To work properly your region should be US (because some items don't ship outside US). If your region is not US - use external VPN, like TunnelBear. 

## Tested on this URLs
url = 'https://www.macys.com/shop/product/tommy-hilfiger-mens-custom-fit-james-polo-shirt-created-for-macys?ID=9595275&CategoryID=20640&swatchColor=Haute%20Red'
url = 'https://www.macys.com/shop/mens-clothing/mens-polo-shirts/Brand,Special_offers/Tommy%20Hilfiger,Super%20Buy?id=20640'
url = 'https://www.macys.com/shop/featured/men%27s-custom~~fit-james-polo-shirt%2C-created-for-macy%27s'
url = 'https://www.macys.com/shop/mens-clothing/mens-polo-shirts/Special_offers/Limited-Time%20Special?id=20640'
url = 'https://www.macys.com/shop/featured/sdfsdfsdfsfd'
url = 'https://www.macys.com/shop/mens-clothing/mens-polo-shirts/Special_offers/Last%20Act?id=20640'
url = 'https://www.macys.com/shop/product/alfani-mens-colorblocked-mesh-polo-shirt-created-for-macys?ID=8757285&CategoryID=20640'
url = 'https://www.macys.com/shop/mens-clothing/mens-slippers/Men_shoe_size_t/6?id=55641'
url = 'https://www.macys.com/shop/product/alfani-mens-soft-touch-stretch-polo-created-for-macys?ID=4266276&CategoryID=20640&swatchColor=Neo+Navy'

## How to use
Paste link that you wanna scrape in url variable.
Bundle and run ruby macys.rb in terminal.
CVS file will be saved in "parsed2csv" directory into macys_scraped.csv the name change filename in the last line: create_csv_file('macys_scraped', @items), 






