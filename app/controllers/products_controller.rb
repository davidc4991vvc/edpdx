class ProductsController < ApplicationController
  before_filter :gate_keeper
  skip_before_filter :gate_keeper, only: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    unless session[:visitor] == 'admin'
      Galileo.create(:controller => 'product',
                       :view => 'index',
                       :ip => request.remote_ip,
                       :referrer => request.referer)
    end


    if params[:type].nil?
      @products = Product.where("quantity > 0")
    else
      @products = Product.where("quantity > 0 and product_category_id = ?", params[:type])
    # elsif params[:type] == 'cutting_boards'
    #   @products = Product.where("quantity > 0 and product_category_id = 1")
    # elsif params[:type] == 'tasters'
    #   @products = Product.where("quantity > 0 and product_category_id = 2")
    # else
    #   @products = Product.where("quantity > 0")
    end
    @expired = Cart.where("active = 't' and updated_at <= now() - interval '1 day'")
    #reset_session
  end

  # GET /products/1
  # GET /products/1.json
  def show
    unless session[:visitor] == 'admin'
      Galileo.create(:controller => 'product',
                       :view => 'show',
                       :ip => request.remote_ip,
                       :object => params[:id])
    end


    @photo = Photo.where(:product_id => params[:id]).order(:sorting)
    @product_note = ProductNote.where(:product_id => params[:id])
    if params[:var] == 'add_to_cart'
      if session[:cart]
        if session[:cart] == ''
          cart = Cart.create(:active => 't')
          session[:cart] = cart.id
          # CartItem.create(:product_id => params[:id],
          #               :quantity => 1,
          #               :cart_id => cart.id)
          #session[:cart] = Time.now.to_f()
        else
          # CartItem.create(:product_id => params[:id],
          #               :quantity => 1,
          #               :cart_id => session[:cart])
        end
      else
        cart = Cart.create(:active => 't')
        session[:cart] = cart.id
        # CartItem.create(:product_id => params[:id],
        #               :quantity => 1,
        #               :cart_id => cart.id)
      end

    quantity = Product.where(:id => params[:id])
    if quantity[0].quantity > 0
      CartItem.create(:product_id => params[:id],
                      :quantity => 1,
                      :cart_id => session[:cart])
      Product.update(quantity, :quantity => quantity[0].quantity - 1)
    end

    redirect_to cart_path(session[:cart])
      #redirect_to action: show, id: params[:id], var: ''
    end
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @photo = Photo.new
    @stock = Photo.where(:product_id => params[:id]).order(:sorting)
    @product_note = ProductNote.new
    @notes = ProductNote.where(:product_id => params[:id])
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:name, :price, :height, :width, :quantity, :description, :product_category_id, :length)
    end
end
