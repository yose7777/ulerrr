import 'package:flutter/material.dart';

class RestaurantUI extends StatelessWidget {
  const RestaurantUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE6E1D8),
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// ================= HERO SECTION =================
            Stack(
              children: [
                Image.network(
                  "https://images.unsplash.com/photo-1558030006-450675393462",
                  height: 420,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Container(
                  height: 420,
                  color: Colors.black.withOpacity(0.45),
                ),

                Positioned(
                  left: 30,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Our menu\npromises to delight\nall your senses",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= GRID MOSAIC =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _imageCard(
                          "https://images.unsplash.com/photo-1544025162-d76694265947",
                          "Sous-Vide\nGrilled Duck",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _imageCard(
                              "https://images.unsplash.com/photo-1547592180-85f173990554",
                              "",
                              height: 160,
                            ),
                            const SizedBox(height: 12),
                            _imageCard(
                              "https://images.unsplash.com/photo-1551024709-8f23befc6f87",
                              "",
                              height: 160,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ================= TEXT BLOCK =================
                  Container(
                    padding: const EdgeInsets.all(30),
                    color: const Color(0xffEFE9DE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Make every bite and sip\nUnforgettable",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                          ),
                          onPressed: () {},
                          child: const Text("Reserve Table"),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ================= FULL IMAGE =================
                  _imageCard(
                    "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
                    "Experience the heart\nof Côte & Cendre",
                    height: 260,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// ================= REUSABLE IMAGE CARD =================
  static Widget _imageCard(String image, String title,
      {double height = 320}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            image,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        if (title.isNotEmpty)
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
      ],
    );
  }
}
