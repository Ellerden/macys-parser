require 'nokogiri'
require 'open-uri'
require 'selenium-webdriver'
require 'csv'
require 'byebug'

def parse_page(link)
  attempts = 0
  begin
    # Macy's blocks scraping and denies access with headless chrome
    # options = Selenium::WebDriver::Chrome::Options.new
    # options.add_argument('--headless')
    # profile = Selenium::WebDriver::Chrome::Profile.new
    # profile['network.http.use-cache'] = false
    # profile['browser.cache.offline.enable'] = false
    driver = Selenium::WebDriver.for :chrome # , profile: profile
    driver.manage.delete_all_cookies
    driver.manage.window.maximize
    driver.navigate.to(link)
    parsed_page = Nokogiri::HTML(driver.page_source)
    driver.save_screenshot 'screenshot1.png'
    driver.quit
    parsed_page
  rescue Net::ReadTimeout => e
    if attempts <= 1
      puts 'Timeout error... retrying connection'
      attempts += 1
      retry
    else
      raise
    end
  end
end

def get_item_info(parsed_page)
  item_hash = {}
  # General info
  item_hash['color'] = parsed_page.at_css('div.color-header strong').text
  item_hash['title'] = parsed_page.at_css('div[data-auto=product-title] h1').text.strip
  item_hash['brand'] = parsed_page.at_css('div[data-auto=product-title] h4 a').text.strip
  item_hash['details'] = parsed_page.at_css('div[data-el=details] p[data-auto=product-description]').text.strip
  item_hash['webid'] = parsed_page.css('div[data-el=details] ul[data-auto=product-description-bullets] li').last.text.gsub!('Web ID: ', '').to_i
  item_hash['pictures'] = get_pictures(parsed_page)

  # Prices
  item_hash['main_price'] = parsed_page.at_css('div[data-el=price-details] div[data-auto=main-price]').text.strip.gsub!(/[A-Za-z$]/, '').to_f
  # it could be not on sale
  sale_price = parsed_page.at_css('div[data-el=price-details] span[data-auto=sale-price]')
  if sale_price
    item_hash['sale_price'] = sale_price.text.strip.gsub!(/[A-Za-z$]/, '').to_f
    # sometimes we don't have precent off - so we need to calculate discount precent
    discount = parsed_page.at_css('div[data-el=price-details] span[data-auto=sale-price] span[data-auto=percent-off]')
    item_hash['precent_off'] = discount ? discount.text.gsub!(/[A-Za-z$%()]/, '').strip.to_i : calculate_discount(item_hash['main_price'], item_hash['sale_price'])
  else
    item_hash['sale_price'] = ''
    item_hash['precent_off'] = ''
  end

  # Sizes /excluding unavailable
  sizes = parsed_page.css('div[data-el=sizes] li[aria-disabled=false]').text.gsub(/\s+/, ' ').reverse.chop.reverse.chop
  item_hash['sizes'] = sizes.tr(' ', '/')

  item_hash
end

def get_pictures(parsed_page)
  alt_pictures = parsed_page.css('div[data-auto=alternate-images] li')
  image = ''
  if alt_pictures.count != 0
    i = 0
    while i < alt_pictures.count
      source = parsed_page.css('div.scroller-wrp li.main-img picture')[i]
      image += source.at_css('source')['srcset'].split('?')[0] + ' '
      i += 1
    end
    image.chop
  # if only one picture - it's stored in dif container
  else
    image = parsed_page.at_css('div.scroller-wrp li.main-img img')['src'].split('?')[0]
  end
end

def get_item_colors(parsed_page)
  # byebug
  colors_count = parsed_page.css('div.color-way-tier ul.color-swatch-collection li').size
  i = 0
  colors = []
  while i < colors_count
    colors << parsed_page.css('div.color-way-tier ul.color-swatch-collection li div')[i]['aria-label']
    i += 1
  end
  colors
end

def calculate_discount(main_price, sale_price)
  (100 - ((sale_price * 100) / main_price)).round
end

def create_csv_file(filename, items_array)
  CSV.open("parsed2csv/#{filename}.csv", 'w') do |file|
    file << ['Title', 'Color', 'Description', 'Brand', 'Pictures', 'Price', 'Sale Price', 'Precent Off', 'Sizes', 'WebID']
    items_array.each do |item|
      file << [item['title'], item['color'], item['details'], item['brand'],
               item['pictures'], item['main_price'], item['sale_price'],
               item['precent_off'], item['sizes'], item['webid']]
    end
  end
end

def url_color_add(link, color)
  parameters = URI.parse(link).query
  main_link = link.split(parameters)[0] # get https://www.macys.com/shop/product/smth?
  item_id = parameters.split('&')[0] # get ID=7128339389
  new_link = main_link + item_id + "&swatchColor=#{URI.encode(color)}" # get right link for color
end

def parse_dif_colors_as_dif_items(parsed_page, default_url, colors)
  colors.each do |color|
    # so not to parse default color twice - we've already parsed this page when counted all colors
    unless color == colors[0]
      parsed_page = parse_page(url_color_add(default_url, color))
      #byebug
    end
    @items << get_item_info(parsed_page)
  end
end

def absolute_address(_parsed_page, link)
  link.insert(0, 'https://www.macys.com') unless link.match('https://www.macys.com')
  link
end

def pagination(parsed_page)
  all_products_on_page = parsed_page.css('div.productThumbnail')

  all_products_on_page.each do |item|
    item_link = absolute_address(parsed_page, item.at_css('div.productThumbnailImage a.productDescLink')['href'])
    item_parsed_page = parse_page(item_link)
    colors = get_item_colors(item_parsed_page)

    parse_dif_colors_as_dif_items(item_parsed_page, item_link, colors)
  end
end

url = 'https://www.macys.com/shop/product/tommy-hilfiger-mens-custom-fit-james-polo-shirt-created-for-macys?ID=9595275&CategoryID=20640&swatchColor=Haute%20Red'

parsed_page = parse_page(url)
@items = []

# if we have product page - not category or search
if url.match('https://www.macys.com/shop/product/')
  # get list of all the colors
  colors = get_item_colors(parsed_page)
  parse_dif_colors_as_dif_items(parsed_page, url, colors)

# if we have more than one product (this is shown in the address) - then we need to walk through the links
else
  results = parsed_page.at_css('div[id=resultsFound] span[id=productCount]').text.to_i
  next_page = parsed_page.at_css('ul.pagePagination li.next-page')
  # if we have results on one page. (60 - is a limit per page)
  pagination(parsed_page) if (results > 0) && (results <= 60)

  # if we have multiple pages
  while next_page
    pagination(parsed_page)
    next_page = parsed_page.at_css('ul.pagePagination li.next-page')
    # if we have multiple pages, condition is false when last page - so we exit the loop
    if next_page
      next_page_url = absolute_address(parsed_page, next_page.at_css('a')['href'])
      parsed_page = parse_page(next_page_url)
    end
  end
end

create_csv_file('macys_scraped', @items)
