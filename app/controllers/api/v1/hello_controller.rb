class Api::V1::HelloController < ApplicationController
    def index
        render json: "Hello Rails"
    end
end
