class Envspec < Formula
	desc "Modular CLI for setting up development environments"
	homepage "http://github.com/adriancmiranda/envspec"
	url "https://github.com/adriancmiranda/envspec/releases/download/v0.0.1/envspec-v0.0.1.tar.gz"
	sha256 "8b5c9c585969773d8ab942d7e8dfa7d318fa6424b3a849c846ab330876de36c1"
	license "MIT"

	depends_on "bash"
	depends_on "gum" => :optional

	def install
		bin.install "requirements" => "envspec"
		prefix.install "examples", "README.md", "LICENSE"
	end

	test do
		assert_match "Uso:", shell_output("#{bin}/envspec 2>&1", 1)
	end
end
