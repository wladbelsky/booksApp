require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'net/http'
require 'json'

class BookController < Rho::RhoController
  include BrowserHelper

  # GET /Book
  def index
    @books = Book.find(:all)
    render :back => '/app'
  end

  # GET /Book/{1}
  def show
    @book = Book.find(@params['id'])
    if @book
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Book/new
  def new
    @book = Book.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Book/{1}/edit
  def edit
    @book = Book.find(@params['id'])
    if @book
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Book/create
  def create
    @book = Book.create(@params['book'])
    redirect :action => :index
  end

  # POST /Book/{1}/update
  def update
    @book = Book.find(@params['id'])
    #@book.update_attributes(@params['book']) if @book
    jsn = Rho::JSON.parse(Rho::Network.get({
                                               url: 'https://www.googleapis.com/books/v1/volumes?q=isbn:' + @params['book']['isbn'],
                                               headers: {'Content-Type' => 'application/json', 'Accept' => 'application/json'},
                                               verifyPeerCertificate: false
                                           })['body'].to_s)
    if jsn['totalItems'] != 0
      unless jsn['items'][0]['volumeInfo'].key?('imageLinks')
        pic = 'https://books.google.ru/googlebooks/images/no_cover_thumb.gif'
      else
        pic = jsn['items'][0]['volumeInfo']['imageLinks']['thumbnail']
      end
      @book.update_attributes(
          :name => jsn['items'][0]['volumeInfo']['title'],
          :author => jsn['items'][0]['volumeInfo']['authors'].join(', ').force_encoding("utf-8"),#if null crashes(((
          :isbn => @params['book']['isbn'],
          :picture => pic)
      redirect :action => :index
    else
      @err = 'can\'t find find book with this number: ' +  @params['book']['isbn']
      render :action => :result
    end

  end

  # POST /Book/{1}/delete
  def delete
    @book = Book.find(@params['id'])
    @book.destroy if @book
    redirect :action => :index
  end

  #my code behind this line
  # -----------------------

  def take_isbn
    Rho::Barcode.take({}, url_for(:action => :take_callback))
    #redirect :action => :result
  end

  def take_callback
    @params.delete("rho_callback")
    Rho::WebView.navigate url_for :action => :take_picture, :query => @params
  end

  def result#legacy
    #if @params["status"] == "ok"
     # @params.delete("rho_callback")
     # Rho::WebView.navigate url_for :action => :take_picture, :query => @params
    #end
    render :action => :result
  end

  def take_picture
    unless @params.empty?
      @result = @params
      #jsn = JSON.parse(Net::HTTP.get(URI('https://www.googleapis.com/books/v1/volumes?q=isbn:'+@result['barcode'])))
      jsn = Rho::JSON.parse(Rho::Network.get({
                                                 url: 'https://www.googleapis.com/books/v1/volumes?q=isbn:' + @result['barcode'],
                                                 headers: {'Content-Type' => 'application/json', 'Accept' => 'application/json'},
                                                 verifyPeerCertificate: false
                                             })['body'].to_s)
      if jsn['totalItems'] != 0
        unless jsn['items'][0]['volumeInfo'].key?('imageLinks')
          pic = 'https://books.google.ru/googlebooks/images/no_cover_thumb.gif'
        else
          pic = jsn['items'][0]['volumeInfo']['imageLinks']['thumbnail']
        end
        @book = Book.create(
            :name => jsn['items'][0]['volumeInfo']['title'],
            :author => jsn['items'][0]['volumeInfo']['authors'].join(', ').force_encoding("utf-8"),#if null crashes(((
            :isbn => @result["barcode"],
            :picture => pic)
        redirect :action => :index
      else
        @err = 'can\'t find find book with this number: ' +  @result["barcode"]
        render :action => :result
      end
    end
    #render :action => :result

  end

  def test

  end
end
