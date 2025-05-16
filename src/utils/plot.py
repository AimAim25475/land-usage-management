import matplotlib.pyplot as plt
import numpy as np

def visualize_with_graph(predicted_mask, class_labels, **images):
    """
    Visualize images, including the predicted mask, and add a bar chart showing class percentages in the predicted mask.
    """
    # Calculate class percentages
    unique, counts = np.unique(predicted_mask, return_counts=True)
    total_pixels = predicted_mask.size
    percentages = (counts / total_pixels) * 100

    # Ensure all classes are represented in the bar chart
    class_counts = np.zeros(len(class_labels), dtype=int)
    for u, c in zip(unique, counts):
        if u < len(class_labels):
            class_counts[u] = c
    percentages = (class_counts / total_pixels) * 100

    # Plot images, predicted mask, and bar chart
    n = len(images) + 2  # Add one for the predicted mask and one for the bar chart
    fig = plt.figure(figsize=(18, 6))
    for i, (name, image) in enumerate(images.items()):
        plt.subplot(1, n, i + 1)
        plt.xticks([])
        plt.yticks([])
        plt.title(' '.join(name.split('_')).title())
        plt.imshow(image)

    # Add predicted mask
    plt.subplot(1, n, len(images) + 1)
    plt.xticks([])
    plt.yticks([])
    plt.title("Predicted Mask")
    plt.imshow(predicted_mask, cmap='tab10', vmin=0, vmax=len(class_labels) - 1)

    # Add bar chart
    plt.subplot(1, n, n)
    bars = plt.bar(class_labels, percentages, color=plt.cm.tab10(range(len(class_labels))))
    for bar, percent in zip(bars, percentages):
        plt.text(bar.get_x() + bar.get_width() / 2.0, bar.get_height(), f'{percent:.2f}%', ha='center', va='bottom')
    plt.title("Class Distribution")
    plt.ylabel("Percentage")
    plt.xticks(rotation=45)

    return fig