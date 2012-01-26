require_relative "../lib/fruity"

compare do
  one       { 42.nil? }
  two       { 42.nil?; 42.nil? }
end

compare do
  two       { 42.nil?; 42.nil? }
  two_again { 42.nil?; 42.nil? }
  three     { 42.nil?; 42.nil?; 42.nil? }
  four      { 42.nil?; 42.nil?; 42.nil?; 42.nil? }
  five      { 42.nil?; 42.nil?; 42.nil?; 42.nil?; 42.nil? }
end
