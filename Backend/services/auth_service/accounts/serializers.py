from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='first_name')

    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'date_joined']


class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField(max_length=150)
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate_full_name(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Họ tên không được để trống.')
        return value

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(username=email).exists():
            raise serializers.ValidationError('Email này đã được sử dụng.')
        return email

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Mật khẩu xác nhận không khớp.'})
        user = User(username=attrs['email'], email=attrs['email'], first_name=attrs['full_name'])
        try:
            validate_password(attrs['password'], user)
        except DjangoValidationError as error:
            raise serializers.ValidationError({'password': list(error.messages)})
        return attrs

    def create(self, validated_data):
        # The email is used as username so that each email maps to exactly one account
        return User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['full_name'],
        )


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Log in with email + password instead of username + password."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields.pop(self.username_field)
        self.fields['email'] = serializers.EmailField(write_only=True)

    def validate(self, attrs):
        attrs[self.username_field] = attrs.pop('email').strip().lower()
        return super().validate(attrs)
