require 'rails_helper'

RSpec.describe 'Auth', type: :request do

  let!(:user) { create(:user) }
  let(:json) { JSON.parse(response.body) }
  let(:expected_response_signin_properties) do
    {
      'user' => {
        'id' => be_a(Numeric),
        'uid' => be_a(String),
        'email' => be_a(String),
        'name' => be_a(String),
        'provider' => eq('email'),
        'allow_password_change' => be(true) | be(false),
      },
      'access_token' => be_a(String),
      'expiry' => be_a(String),
    }
  end

  describe 'POST /api/v1/auth' do
    context 'ユーザー情報が正しい場合' do
      let(:params) {{name: 'test', email: 'test@it.com', password: 'password'}}
      before do
        post '/api/v1/auth', params: params
      end
      let(:expected_response_object) do
        auth = User.last
        {
          'id' => "#{auth.id}".to_i,
          'provider' => 'email',
          'uid' => 'test@it.com',
          'allow_password_change' => false,
          'name' => 'test',
          'email' => 'test@it.com',
          'created_at' => "#{auth.created_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')}",
          'updated_at' => "#{auth.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')}"
        }
      end

      it 'HTTPステータスが200であること' do
        expect(response).to have_http_status 200
      end

      it '新規ユーザーが追加されていること' do
        expect(json['status']).to eq("success")
        expect(json['data']).to match(expected_response_object)
      end
    end

    context 'emailが空文字の場合' do
      let(:params) {{name: 'test', email: '', password: 'password'}}
      before do
        post '/api/v1/auth', params: params
      end

      it 'HTTPステータスが422であること' do
        expect(response).to have_http_status 422
      end

      it 'レスポンスが正しいこと' do
        expect(json['status']).to eq("error")
        expect(json['errors']['full_messages']).to include("Email can't be blank")
      end
    end

    context 'emailがメールアドレスでない場合' do
      let(:params) {{name: 'test', email: 'testit.com', password: 'password'}}
      before do
        post '/api/v1/auth', params: params
      end

      it 'HTTPステータスが422であること' do
        expect(response).to have_http_status 422
      end

      it 'レスポンスが正しいこと' do
        expect(json['status']).to eq("error")
        expect(json['errors']['full_messages']).to include('Email is not an email')
      end
    end

    context '既存のユーザーとemailが重複している場合' do
      let(:params) {{name: 'test', email: user['email'], password: 'password'}}
      before do
        post '/api/v1/auth', params: params
      end

      it 'HTTPステータスが422であること' do
        expect(response).to have_http_status 422
      end

      it 'レスポンスが正しいこと' do
        expect(json['status']).to eq("error")
        expect(json['errors']['full_messages']).to include('Email has already been taken')
      end
    end

    context 'Passwordが空文字の場合' do
      let(:params) {{name: 'test', email: 'test+1@it.com', password: ''}}
      before do
        post '/api/v1/auth', params: params
      end

      it 'HTTPステータスが422であること' do
        expect(response).to have_http_status 422
      end

      it 'レスポンスが正しいこと' do
        expect(json['status']).to eq("error")
        expect(json['errors']['full_messages']).to include("Password can't be blank")
      end
    end

    context 'Passwordが6文字以下の場合' do
      let(:params) {{name: 'test', email: 'test+1@it.com', password: '12345'}}
      before do
        post '/api/v1/auth', params: params
      end

      it 'HTTPステータスが422であること' do
        expect(response).to have_http_status 422
      end

      it 'レスポンスが正しいこと' do
        expect(json['status']).to eq("error")
        expect(json['errors']['full_messages']).to include("Password is too short (minimum is 6 characters)")
      end
    end
  end

  describe 'POST /api/v1/auth/sign_in' do
    context 'ユーザー情報が正しい場合' do
      before do
        post '/api/v1/auth/sign_in', params: {email:user['email'], password: 'password'}
      end

      it 'HTTPステータスが200であること' do
        expect(response).to have_http_status 200
      end

      it 'レスポンスパラメーターが正しいこと' do
        expect(json).to include(expected_response_signin_properties)
      end

      it 'ユーザー情報に相違がないこと' do
        expect(json['user']['email']).to eq(user['email'])
      end
    end

    shared_context '異常系' do
      it 'HTTPステータスが401であること' do
        expect(response).to have_http_status 401
      end

      it 'レスポンスが正しいこと' do
        expect(json['success']).to eq(false)
        expect(json['errors']).to include('Invalid login credentials. Please try again.')
      end
    end

    context 'ユーザー情報のemailが間違っている場合' do
      before do
        post '/api/v1/auth/sign_in', params: {email: 'dummy@it.com', password: 'password'}
      end

      include_context '異常系'
    end

    context 'ユーザー情報のpasswordが間違っている場合' do
      before do
        post '/api/v1/auth/sign_in', params: {email: user['email'], password: 'passwordxxx'}
      end

      include_context '異常系'
    end
  end

  def auth_headers
    post '/api/v1/auth/sign_in', params: {email:user['email'], password: 'password'}
    {
      'Authorization' => "Bearer #{json['access_token']}",
      'Content-Type' => 'application/json'
    }
  end

  describe 'GET /api/v1/whoami' do
    context 'Authorization Headerがない場合' do
      before do
        get '/api/v1/whoami', headers: { 'Content-Type' => 'application/json' }
      end

      it 'HTTPステータスが401であること' do
        expect(response).to have_http_status 401
      end

      it 'レスポンスが正しいこと' do
        expect(json['errors']).to include("You need to sign in or sign up before continuing.")
      end
    end

    context 'Authorization Headerがある場合' do
      before do
        get '/api/v1/whoami', headers: auth_headers
      end

      it 'HTTPステータスが200であること' do
        expect(response).to have_http_status 200
      end
      # it 'レスポンスが正しいこと' do
      #   expect(json).to eq()
      # end
    end
  end

end
