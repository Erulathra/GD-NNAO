from PIL import Image
import numpy as np
from matplotlib import pyplot as plt

databases = ["mesa1", "mesa2", "mesa3", "mesa4", "mesa_props"]

IMAGE_WIDTH  = 1280
IMAGE_HEIGHT = 720
SSAO_IMAGE_BPP = 4 # float grayscale
NORM_IMAGE_BPP = 4 * 4 # float RGBA 

NEAR = 0.1
FAR = 1000.

def convert_norm(database, image_index):
    norm_path = "./data/raw/%s/normalCam/%s.%i.bin" % (databases[database], databases[database], image_index)
    norm_data = None
    with open(norm_path, "rb") as norm_file:
        image_data = norm_file.read(NORM_IMAGE_BPP * IMAGE_WIDTH * IMAGE_HEIGHT)
        image_array = np.frombuffer(image_data, dtype=np.float32)
        image_array = image_array.reshape((IMAGE_HEIGHT, IMAGE_WIDTH, 4))

        norm_plus_depth = np.dsplit(image_array, [3])

        norm_array = norm_plus_depth[0]
        norm_array = (norm_array * 255).astype(np.uint8)

        norm_image = Image.fromarray(norm_array, 'RGB')
        norm_image.save("out/norm.png")

        depth_array = np.squeeze(norm_plus_depth[1])

        depth_array = (depth_array - depth_array.min()) / (depth_array.max() - depth_array.min()) * 255

        depth_array = depth_array.astype(np.uint8)
        norm_image = Image.fromarray(depth_array, 'L')
        norm_image.save("out/depth.png")

def convert_ssao(database, image_index):
    ssao_path = "./data/raw/%s/AO/%s.%i.bin" % (databases[database], databases[database], image_index)
    ssao_data = None
    with open(ssao_path, "rb") as ssao_file:
        ssao_data = ssao_file.read(SSAO_IMAGE_BPP * IMAGE_WIDTH * IMAGE_HEIGHT)
        ssao_array = np.frombuffer(ssao_data, dtype=np.float32)
        ssao_array = ssao_array.reshape((IMAGE_HEIGHT, IMAGE_WIDTH))

        ssao_array = ((1. - ssao_array) * 255).astype(np.uint8)

        ssao_image : Image = Image.fromarray(ssao_array, 'L')
        ssao_image.save("out/ssao.png")


def main():
    convert_ssao(0, 1)
    convert_norm(0, 1)


if __name__ == "__main__":
    main()