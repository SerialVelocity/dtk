/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module images;

import dtk;

void main()
{
    auto app = new App;

    // Get the reference to the implicitly created main window.
    auto window = app.mainWindow;
    window.title = "Images example";
    window.size = Size(200, 80);

    // Position it in the center.
    window.centerWindow();

    // Load an image.
    auto image = new Image("images/mail-icon.png");

    // Create a button.
    auto button = new Button(window);

    // Set the button's image.
    button.image = image;

    // Create a label that combines an image with some text.
    auto label = new Label(window);
    label.image = new Image("images/rss-icon.png");
    label.text = "RSS Feed";

    // Position the image above the text
    label.compound = Compound.top;

    // Position the button and the label next to each other in a grid.
    button.grid.setRow(0).setCol(0);
    label.grid.setRow(0).setCol(1);

    app.run();
}
