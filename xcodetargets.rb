class Xcodetargets < Formula
  desc "Swift implicit import checks for SPM packages and Xcodeproj"
  homepage "https://github.com/michaelversus/XcodeTargets"
  url "https://github.com/michaelversus/XcodeTargets.git", tag: "0.1.7"
  version "0.1.7"

  depends_on "xcode": [:build]

  def install
    system "make", "install", "prefix=#{prefix}"
  end

  test do
    system "#{bin}/Xcodetargets", "list"
  end
end
