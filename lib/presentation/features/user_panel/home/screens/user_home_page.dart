import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
      ),
      debugShowCheckedModeBanner: false,
      home: const UserHomePage(),
    );
  }
}

// This is the SVG data for the illustration at the top of the screen.
// It's included directly in the code to avoid needing extra asset files.
const String carAndCitySvg = '''
<svg width="375" height="200" viewBox="0 0 375 200" fill="none" xmlns="http://www.w3.org/2000/svg">
<mask id="mask0_1_2" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="375" height="200">
<rect width="375" height="200" fill="#D9D9D9"/>
</mask>
<g mask="url(#mask0_1_2)">
<rect x="-3" y="115" width="381" height="85" fill="#F8F8F8"/>
<g opacity="0.5">
<rect x="25" y="135" width="10" height="40" fill="#D9D9D9"/>
<rect x="45" y="125" width="10" height="50" fill="#D9D9D9"/>
<rect x="65" y="145" width="10" height="30" fill="#D9D9D9"/>
<rect x="85" y="115" width="10" height="60" fill="#D9D9D9"/>
<rect x="105" y="140" width="10" height="35" fill="#D9D9D9"/>
<rect x="125" y="120" width="10" height="55" fill="#D9D9D9"/>
<rect x="230" y="135" width="10" height="40" fill="#D9D9D9"/>
<rect x="250" y="125" width="10" height="50" fill="#D9D9D9"/>
<rect x="270" y="145" width="10" height="30" fill="#D9D9D9"/>
<rect x="290" y="115" width="10" height="60" fill="#D9D9D9"/>
<rect x="310" y="140" width="10" height="35" fill="#D9D9D9"/>
<rect x="330" y="120" width="10" height="55" fill="#D9D9D9"/>
<rect x="350" y="130" width="10" height="45" fill="#D9D9D9"/>
</g>
<path d="M125.5 174.5L145.5 174.5" stroke="#C4C4C4" stroke-width="2" stroke-linecap="round" stroke-dasharray="4 4"/>
<path d="M230.5 174.5L250.5 174.5" stroke="#C4C4C4" stroke-width="2" stroke-linecap="round" stroke-dasharray="4 4"/>
<path d="M152 145H108C106.895 145 106 145.895 106 147V170C106 171.105 106.895 172 108 172H152C153.105 172 154 171.105 154 170V147C154 145.895 153.105 145 152 145Z" fill="white" stroke="#4F4F4F" stroke-width="2"/>
<circle cx="130" cy="158" r="5" fill="#E0E0E0"/>
<rect x="116" y="166" width="28" height="2" rx="1" fill="#E0E0E0"/>
<path d="M260 148C260 144.686 257.314 142 254 142C250.686 142 248 144.686 248 148C248 150.5 249.5 154.5 254 162C258.5 154.5 260 150.5 260 148Z" fill="white" stroke="#4F4F4F" stroke-width="2"/>
<circle cx="254" cy="148" r="2" fill="#4F4F4F"/>
<path d="M218 153.381C218 150.242 215.758 147.619 213 147.619H171C168.242 147.619 166 150.242 166 153.381V166.5C166 171.194 169.806 175 174.5 175H209.5C214.194 175 218 171.194 218 166.5V153.381Z" fill="#F0C414"/>
<path d="M172 158H212V168C212 170.209 210.209 172 208 172H176C173.791 172 172 170.209 172 168V158Z" fill="#FFD953"/>
<circle cx="178" cy="175" r="5" fill="white" stroke="#4F4F4F" stroke-width="2"/>
<circle cx="206" cy="175" r="5" fill="white" stroke="#4F4F4F" stroke-width="2"/>
</g>
</svg>
''';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar මගින් යෙදුමේ ඉහළින් ඇති bar එක නිර්මාණය කරයි
      appBar: AppBar(
        // AppBar එකโปร่งใส (transparent) කිරීම
        backgroundColor: Colors.transparent,
        // elevation: 0 මගින් AppBar එකට යටින් ඇති shadow එක ඉවත් කරයි
        elevation: 0,
        // AppBar එකේ වම් පැත්තේ තැබිය යුතු widget එක
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black,
          ), // Hamburger menu icon
          onPressed: () {
            // මෙනුව විවෘත කිරීම සඳහා වන කේතය මෙහි යොදන්න
            print('Menu button tapped!');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          // Widgets සිරස් අතට සකස් කිරීම
          children: [
            // ඉහළින් ඇති චිත්‍රය පෙන්වීම සඳහා
            SizedBox(
              height: 200, // චිත්‍රයේ උස
              width: double.infinity, // තිරයේ සම්පූර්ණ පළල
              child: SvgPicture.string(
                carAndCitySvg, // අප ඉහතින් නිර්වචනය කළ SVG දත්ත
                fit: BoxFit.contain, // SVG එක කොටුවට ගැලපෙන සේ සකස් කිරීම
              ),
            ),
            const SizedBox(height: 40), // ඉඩක් තැබීම
            // ප්‍රධාන ශීර්ෂ පාඨය
            const Text(
              'Hi, nice to meet you!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // උප ශීර්ෂ පාඨය
            Text(
              'Choose you pickup location',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[500], // පින්තූරයේ ඇති අළු පැහැයට සමාන වර්ණයක්
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            // "Use current location" බොත්තම
            OutlinedButton.icon(
              onPressed: () {
                print('Use current location tapped!');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fetching your location...')),
                );
              },
              // පින්තූරයේ ඇති icon එකට සමාන icon එකක්
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('use current location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE5B400),
                side: const BorderSide(color: Color(0xFFF0C414), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // "Select it manually" බොත්තම
            TextButton(
              onPressed: () {
                print('Select manually tapped!');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening map to select location...'),
                  ),
                );
              },
              child: const Text(
                'select it manually',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
