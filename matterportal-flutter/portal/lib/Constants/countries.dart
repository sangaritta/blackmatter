class Country {
  final String name;
  final String code;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.flag,
  });
}

final List<Country> countries = [
  const Country(name: 'Afghanistan', code: 'AF', flag: '🇦🇫'),
  const Country(name: 'Albania', code: 'AL', flag: '🇦🇱'),
  const Country(name: 'Algeria', code: 'DZ', flag: '🇩🇿'),
  const Country(name: 'Andorra', code: 'AD', flag: '🇦🇩'),
  const Country(name: 'Angola', code: 'AO', flag: '🇦🇴'),
  const Country(name: 'Antigua and Barbuda', code: 'AG', flag: '🇦🇬'),
  const Country(name: 'Argentina', code: 'AR', flag: '🇦🇷'),
  const Country(name: 'Armenia', code: 'AM', flag: '🇦🇲'),
  const Country(name: 'Australia', code: 'AU', flag: '🇦🇺'),
  const Country(name: 'Austria', code: 'AT', flag: '🇦🇹'),
  const Country(name: 'Azerbaijan', code: 'AZ', flag: '🇦🇿'),
  const Country(name: 'Bahamas', code: 'BS', flag: '🇧🇸'),
  const Country(name: 'Bahrain', code: 'BH', flag: '🇧🇭'),
  const Country(name: 'Bangladesh', code: 'BD', flag: '🇧🇩'),
  const Country(name: 'Barbados', code: 'BB', flag: '🇧🇧'),
  const Country(name: 'Belarus', code: 'BY', flag: '🇧🇾'),
  const Country(name: 'Belgium', code: 'BE', flag: '🇧🇪'),
  const Country(name: 'Belize', code: 'BZ', flag: '🇧🇿'),
  const Country(name: 'Benin', code: 'BJ', flag: '🇧🇯'),
  const Country(name: 'Bhutan', code: 'BT', flag: '🇧🇹'),
  const Country(name: 'Bolivia', code: 'BO', flag: '🇧🇴'),
  const Country(name: 'Bosnia and Herzegovina', code: 'BA', flag: '🇧🇦'),
  const Country(name: 'Botswana', code: 'BW', flag: '🇧🇼'),
  const Country(name: 'Brazil', code: 'BR', flag: '🇧🇷'),
  const Country(name: 'Brunei', code: 'BN', flag: '🇧🇳'),
  const Country(name: 'Bulgaria', code: 'BG', flag: '🇧🇬'),
  const Country(name: 'Burkina Faso', code: 'BF', flag: '🇧🇫'),
  const Country(name: 'Burundi', code: 'BI', flag: '🇧🇮'),
  const Country(name: 'Cambodia', code: 'KH', flag: '🇰🇭'),
  const Country(name: 'Cameroon', code: 'CM', flag: '🇨🇲'),
  const Country(name: 'Canada', code: 'CA', flag: '🇨🇦'),
  const Country(name: 'Cape Verde', code: 'CV', flag: '🇨🇻'),
  const Country(name: 'Central African Republic', code: 'CF', flag: '🇨🇫'),
  const Country(name: 'Chad', code: 'TD', flag: '🇹🇩'),
  const Country(name: 'Chile', code: 'CL', flag: '🇨🇱'),
  const Country(name: 'China', code: 'CN', flag: '🇨🇳'),
  const Country(name: 'Colombia', code: 'CO', flag: '🇨🇴'),
  const Country(name: 'Comoros', code: 'KM', flag: '🇰🇲'),
  const Country(name: 'Congo', code: 'CG', flag: '🇨🇬'),
  const Country(name: 'Costa Rica', code: 'CR', flag: '🇨🇷'),
  const Country(name: 'Croatia', code: 'HR', flag: '🇭🇷'),
  const Country(name: 'Cuba', code: 'CU', flag: '🇨🇺'),
  const Country(name: 'Cyprus', code: 'CY', flag: '🇨🇾'),
  const Country(name: 'Czech Republic', code: 'CZ', flag: '🇨🇿'),
  const Country(name: 'Denmark', code: 'DK', flag: '🇩🇰'),
  const Country(name: 'Djibouti', code: 'DJ', flag: '🇩🇯'),
  const Country(name: 'Dominica', code: 'DM', flag: '🇩🇲'),
  const Country(name: 'Dominican Republic', code: 'DO', flag: '🇩🇴'),
  const Country(name: 'DR Congo', code: 'CD', flag: '🇨🇩'),
  const Country(name: 'Ecuador', code: 'EC', flag: '🇪🇨'),
  const Country(name: 'Egypt', code: 'EG', flag: '🇪🇬'),
  const Country(name: 'El Salvador', code: 'SV', flag: '🇸🇻'),
  const Country(name: 'Equatorial Guinea', code: 'GQ', flag: '🇬🇶'),
  const Country(name: 'Eritrea', code: 'ER', flag: '🇪🇷'),
  const Country(name: 'Estonia', code: 'EE', flag: '🇪🇪'),
  const Country(name: 'Eswatini', code: 'SZ', flag: '🇸🇿'),
  const Country(name: 'Ethiopia', code: 'ET', flag: '🇪🇹'),
  const Country(name: 'Fiji', code: 'FJ', flag: '🇫🇯'),
  const Country(name: 'Finland', code: 'FI', flag: '🇫🇮'),
  const Country(name: 'France', code: 'FR', flag: '🇫🇷'),
  const Country(name: 'Gabon', code: 'GA', flag: '🇬🇦'),
  const Country(name: 'Gambia', code: 'GM', flag: '🇬🇲'),
  const Country(name: 'Georgia', code: 'GE', flag: '🇬🇪'),
  const Country(name: 'Germany', code: 'DE', flag: '🇩🇪'),
  const Country(name: 'Ghana', code: 'GH', flag: '🇬🇭'),
  const Country(name: 'Greece', code: 'GR', flag: '🇬🇷'),
  const Country(name: 'Grenada', code: 'GD', flag: '🇬🇩'),
  const Country(name: 'Guatemala', code: 'GT', flag: '🇬🇹'),
  const Country(name: 'Guinea', code: 'GN', flag: '🇬🇳'),
  const Country(name: 'Guinea-Bissau', code: 'GW', flag: '🇬🇼'),
  const Country(name: 'Guyana', code: 'GY', flag: '🇬🇾'),
  const Country(name: 'Haiti', code: 'HT', flag: '🇭🇹'),
  const Country(name: 'Honduras', code: 'HN', flag: '🇭🇳'),
  const Country(name: 'Hungary', code: 'HU', flag: '🇭🇺'),
  const Country(name: 'Iceland', code: 'IS', flag: '🇮🇸'),
  const Country(name: 'India', code: 'IN', flag: '🇮🇳'),
  const Country(name: 'Indonesia', code: 'ID', flag: '🇮🇩'),
  const Country(name: 'Iran', code: 'IR', flag: '🇮🇷'),
  const Country(name: 'Iraq', code: 'IQ', flag: '🇮🇶'),
  const Country(name: 'Ireland', code: 'IE', flag: '🇮🇪'),
  const Country(name: 'Israel', code: 'IL', flag: '🇮🇱'),
  const Country(name: 'Italy', code: 'IT', flag: '🇮🇹'),
  const Country(name: 'Ivory Coast', code: 'CI', flag: '🇨🇮'),
  const Country(name: 'Jamaica', code: 'JM', flag: '🇯🇲'),
  const Country(name: 'Japan', code: 'JP', flag: '🇯🇵'),
  const Country(name: 'Jordan', code: 'JO', flag: '🇯🇴'),
  const Country(name: 'Kazakhstan', code: 'KZ', flag: '🇰🇿'),
  const Country(name: 'Kenya', code: 'KE', flag: '🇰🇪'),
  const Country(name: 'Kiribati', code: 'KI', flag: '🇰🇮'),
  const Country(name: 'Kuwait', code: 'KW', flag: '🇰🇼'),
  const Country(name: 'Kyrgyzstan', code: 'KG', flag: '🇰🇬'),
  const Country(name: 'Laos', code: 'LA', flag: '🇱🇦'),
  const Country(name: 'Latvia', code: 'LV', flag: '🇱🇻'),
  const Country(name: 'Lebanon', code: 'LB', flag: '🇱🇧'),
  const Country(name: 'Lesotho', code: 'LS', flag: '🇱🇸'),
  const Country(name: 'Liberia', code: 'LR', flag: '🇱🇷'),
  const Country(name: 'Libya', code: 'LY', flag: '🇱🇾'),
  const Country(name: 'Liechtenstein', code: 'LI', flag: '🇱🇮'),
  const Country(name: 'Lithuania', code: 'LT', flag: '🇱🇹'),
  const Country(name: 'Luxembourg', code: 'LU', flag: '🇱🇺'),
  const Country(name: 'Madagascar', code: 'MG', flag: '🇲🇬'),
  const Country(name: 'Malawi', code: 'MW', flag: '🇲🇼'),
  const Country(name: 'Malaysia', code: 'MY', flag: '🇲🇾'),
  const Country(name: 'Maldives', code: 'MV', flag: '🇲🇻'),
  const Country(name: 'Mali', code: 'ML', flag: '🇲🇱'),
  const Country(name: 'Malta', code: 'MT', flag: '🇲🇹'),
  const Country(name: 'Marshall Islands', code: 'MH', flag: '🇲🇭'),
  const Country(name: 'Mauritania', code: 'MR', flag: '🇲🇷'),
  const Country(name: 'Mauritius', code: 'MU', flag: '🇲🇺'),
  const Country(name: 'Mexico', code: 'MX', flag: '🇲🇽'),
  const Country(name: 'Micronesia', code: 'FM', flag: '🇫🇲'),
  const Country(name: 'Moldova', code: 'MD', flag: '🇲🇩'),
  const Country(name: 'Monaco', code: 'MC', flag: '🇲🇨'),
  const Country(name: 'Mongolia', code: 'MN', flag: '🇲🇳'),
  const Country(name: 'Montenegro', code: 'ME', flag: '🇲🇪'),
  const Country(name: 'Morocco', code: 'MA', flag: '🇲🇦'),
  const Country(name: 'Mozambique', code: 'MZ', flag: '🇲🇿'),
  const Country(name: 'Myanmar', code: 'MM', flag: '🇲🇲'),
  const Country(name: 'Namibia', code: 'NA', flag: '🇳🇦'),
  const Country(name: 'Nauru', code: 'NR', flag: '🇳🇷'),
  const Country(name: 'Nepal', code: 'NP', flag: '🇳🇵'),
  const Country(name: 'Netherlands', code: 'NL', flag: '🇳🇱'),
  const Country(name: 'New Zealand', code: 'NZ', flag: '🇳🇿'),
  const Country(name: 'Nicaragua', code: 'NI', flag: '🇳🇮'),
  const Country(name: 'Niger', code: 'NE', flag: '🇳🇪'),
  const Country(name: 'Nigeria', code: 'NG', flag: '🇳🇬'),
  const Country(name: 'North Korea', code: 'KP', flag: '🇰🇵'),
  const Country(name: 'North Macedonia', code: 'MK', flag: '🇲🇰'),
  const Country(name: 'Norway', code: 'NO', flag: '🇳🇴'),
  const Country(name: 'Oman', code: 'OM', flag: '🇴🇲'),
  const Country(name: 'Pakistan', code: 'PK', flag: '🇵🇰'),
  const Country(name: 'Palau', code: 'PW', flag: '🇵🇼'),
  const Country(name: 'Palestine', code: 'PS', flag: '🇵🇸'),
  const Country(name: 'Panama', code: 'PA', flag: '🇵🇦'),
  const Country(name: 'Papua New Guinea', code: 'PG', flag: '🇵🇬'),
  const Country(name: 'Paraguay', code: 'PY', flag: '🇵🇾'),
  const Country(name: 'Peru', code: 'PE', flag: '🇵🇪'),
  const Country(name: 'Philippines', code: 'PH', flag: '🇵🇭'),
  const Country(name: 'Poland', code: 'PL', flag: '🇵🇱'),
  const Country(name: 'Portugal', code: 'PT', flag: '🇵🇹'),
  const Country(name: 'Qatar', code: 'QA', flag: '🇶🇦'),
  const Country(name: 'Romania', code: 'RO', flag: '🇷🇴'),
  const Country(name: 'Russia', code: 'RU', flag: '🇷🇺'),
  const Country(name: 'Rwanda', code: 'RW', flag: '🇷🇼'),
  const Country(name: 'Saint Kitts and Nevis', code: 'KN', flag: '🇰🇳'),
  const Country(name: 'Saint Lucia', code: 'LC', flag: '🇱🇨'),
  const Country(
      name: 'Saint Vincent and the Grenadines', code: 'VC', flag: '🇻🇨'),
  const Country(name: 'Samoa', code: 'WS', flag: '🇼🇸'),
  const Country(name: 'San Marino', code: 'SM', flag: '🇸🇲'),
  const Country(name: 'Sao Tome and Principe', code: 'ST', flag: '🇸🇹'),
  const Country(name: 'Saudi Arabia', code: 'SA', flag: '🇸🇦'),
  const Country(name: 'Senegal', code: 'SN', flag: '🇸🇳'),
  const Country(name: 'Serbia', code: 'RS', flag: '🇷🇸'),
  const Country(name: 'Seychelles', code: 'SC', flag: '🇸🇨'),
  const Country(name: 'Sierra Leone', code: 'SL', flag: '🇸🇱'),
  const Country(name: 'Singapore', code: 'SG', flag: '🇸🇬'),
  const Country(name: 'Slovakia', code: 'SK', flag: '🇸🇰'),
  const Country(name: 'Slovenia', code: 'SI', flag: '🇸🇮'),
  const Country(name: 'Solomon Islands', code: 'SB', flag: '🇸🇧'),
  const Country(name: 'Somalia', code: 'SO', flag: '🇸🇴'),
  const Country(name: 'South Africa', code: 'ZA', flag: '🇿🇦'),
  const Country(name: 'South Korea', code: 'KR', flag: '🇰🇷'),
  const Country(name: 'South Sudan', code: 'SS', flag: '🇸🇸'),
  const Country(name: 'Spain', code: 'ES', flag: '🇪🇸'),
  const Country(name: 'Sri Lanka', code: 'LK', flag: '🇱🇰'),
  const Country(name: 'Sudan', code: 'SD', flag: '🇸🇩'),
  const Country(name: 'Suriname', code: 'SR', flag: '🇸🇷'),
  const Country(name: 'Sweden', code: 'SE', flag: '🇸🇪'),
  const Country(name: 'Switzerland', code: 'CH', flag: '🇨🇭'),
  const Country(name: 'Syria', code: 'SY', flag: '🇸🇾'),
  const Country(name: 'Taiwan', code: 'TW', flag: '🇹🇼'),
  const Country(name: 'Tajikistan', code: 'TJ', flag: '🇹🇯'),
  const Country(name: 'Tanzania', code: 'TZ', flag: '🇹🇿'),
  const Country(name: 'Thailand', code: 'TH', flag: '🇹🇭'),
  const Country(name: 'Timor-Leste', code: 'TL', flag: '🇹🇱'),
  const Country(name: 'Togo', code: 'TG', flag: '🇹🇬'),
  const Country(name: 'Tonga', code: 'TO', flag: '🇹🇴'),
  const Country(name: 'Trinidad and Tobago', code: 'TT', flag: '🇹🇹'),
  const Country(name: 'Tunisia', code: 'TN', flag: '🇹🇳'),
  const Country(name: 'Turkey', code: 'TR', flag: '🇹🇷'),
  const Country(name: 'Turkmenistan', code: 'TM', flag: '🇹🇲'),
  const Country(name: 'Tuvalu', code: 'TV', flag: '🇹🇻'),
  const Country(name: 'Uganda', code: 'UG', flag: '🇺🇬'),
  const Country(name: 'Ukraine', code: 'UA', flag: '🇺🇦'),
  const Country(name: 'United Arab Emirates', code: 'AE', flag: '🇦🇪'),
  const Country(name: 'United Kingdom', code: 'GB', flag: '🇬🇧'),
  const Country(name: 'United States', code: 'US', flag: '🇺🇸'),
  const Country(name: 'Uruguay', code: 'UY', flag: '🇺🇾'),
  const Country(name: 'Uzbekistan', code: 'UZ', flag: '🇺🇿'),
  const Country(name: 'Vanuatu', code: 'VU', flag: '🇻🇺'),
  const Country(name: 'Vatican City', code: 'VA', flag: '🇻🇦'),
  const Country(name: 'Venezuela', code: 'VE', flag: '🇻🇪'),
  const Country(name: 'Vietnam', code: 'VN', flag: '🇻🇳'),
  const Country(name: 'Yemen', code: 'YE', flag: '🇾🇪'),
  const Country(name: 'Zambia', code: 'ZM', flag: '🇿🇲'),
  const Country(name: 'Zimbabwe', code: 'ZW', flag: '🇿🇼'),
];
