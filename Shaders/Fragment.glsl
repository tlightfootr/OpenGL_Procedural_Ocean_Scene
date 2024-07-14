#version 400 core

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct PointLight {    
    vec3 position;
    
    float constant;
    float linear;
    float quadratic;  

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform PointLight pointLight;
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir); 

vec3 CalcDirLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);

vec3 waveNormal(float x, float z);
float calcWaveDx(vec2 p, int i, float x, float z);
float calcWaveDy(vec2 p, int i, float x, float z);

in vec2 TexCoords;
in vec3 FragPos;
in vec3 NormalPos;

float dirVals[] = float[200](0.1181, 0.7204, 0.399, 0.3315, 0.27, 0.0525, 0.7082, 0.573, 0.6913, 0.6627, 0.8906, 0.6152, 0.5396, 0.6569, 0.0348, 0.1966, 0.0246, 0.9251, 0.2854, 0.4396, 0.3261, 0.6801, 0.6628, 0.1879, 0.549, 0.8352, 0.737, 0.3302, 0.5004, 0.597, 0.8465, 0.6073, 0.8697, 0.4528, 0.5772, 0.5376, 0.5698, 0.3914, 0.4541, 0.1949, 0.1713, 0.5778, 0.0912, 0.4045, 0.9188, 0.5455, 0.4215, 0.4241, 0.4257, 0.6538, 0.1291, 0.3638, 0.3057, 0.1002, 0.5306, 0.1247, 0.5095, 0.0901, 0.1599, 0.7645, 0.4373, 0.3378, 0.5803, 0.7635, 0.029, 0.7913, 0.6635, 0.163, 0.56, 0.3703, 0.5552, 0.4412, 0.6287, 0.8771, 0.5801, 0.113, 0.1902, 0.6362, 0.9159, 0.7758, 0.8096, 0.3629, 0.3983, 0.864, 0.4521, 0.8314, 0.382, 0.8822, 0.4884, 0.4091, 0.4368, 0.7526, 0.8525, 0.4033, 0.0497, 0.4059, 0.3694, 0.2164, 0.9247, 0.9183, 0.5486, 0.5435, 0.7661, 0.0724, 0.6063, 0.4446, 0.1245, 0.7107, 0.4154, 0.2173, 0.5605, 0.1681, 0.1123, 0.1818, 0.0172, 0.436, 0.949, 0.1364, 0.9832, 0.0322, 0.2651, 0.8959, 0.9999, 0.2043, 0.6699, 0.0394, 0.4548, 0.8251, 0.4208, 0.5691, 0.7287, 0.7869, 0.6427, 0.0486, 0.0236, 0.2713, 0.1181, 0.0416, 0.1214, 0.283, 0.9385, 0.9949, 0.3472, 0.5112, 0.9528, 0.7729, 0.5303, 0.8539, 0.4347, 0.1028, 0.6847, 0.6711, 0.5477, 0.9222, 0.6032, 0.2049, 0.9149, 0.6373, 0.8468, 0.7557, 0.8362, 0.2838, 0.8897, 0.7383, 0.0256, 0.8907, 0.9911, 0.8871, 0.2335, 0.5352, 0.6809, 0.3463, 0.9121, 0.1994, 0.2212, 0.538, 0.7594, 0.5238, 0.8832, 0.4659, 0.2247, 0.6241, 0.8734, 0.9455, 0.9748, 0.0537, 0.272, 0.149, 0.65, 0.4057, 0.2471, 0.0017, 0.7419, 0.8441, 0.2318, 0.7489, 0.6465, 0.2379, 0.2845, 0.9995);

uniform vec3 viewPos;
uniform Material material;
uniform mat4 model;
uniform float time;
uniform samplerCube skybox;

const int num = 15;
const float e = 2.71828182;

out vec4 FragColor;

void main()
{
    vec3 norm = mat3(transpose(inverse(model))) * waveNormal(NormalPos.x, NormalPos.z);
    norm = normalize(norm);

    vec3 viewDir = normalize(viewPos - FragPos);


    FragColor = vec4(CalcDirLight(pointLight, norm, FragPos, viewDir), 1.0);
}

// point light
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);

    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    vec3 ambient = light.ambient * vec3(0.6, 0.6, 0.6);
    vec3 diffuse = light.diffuse * diff * vec3(0.6, 0.6, 0.6);
    vec3 specular = light.specular * spec * vec3(1.0, 1.0, 1.0);

    return ambient + diffuse + specular;
}

// dir light
vec3 CalcDirLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 lightDir = normalize(-vec3(0.5, -1.0, 1.7));
    // diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);

    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    // reflection
    vec3 R = reflect(-viewDir, normal);
    float fresnel = pow(1 - max(dot(normalize(viewDir), vec3(0.0, 1.0, 0.0)), 0), 5);
    vec3 reflectCol = texture(skybox, R).rgb * fresnel;

    vec3 ambient = light.ambient * vec3(0.6, 0.6, 0.6);
    vec3 diffuse = light.diffuse * diff * vec3(0.6, 0.6, 0.6);
    vec3 specular = light.specular * spec * vec3(1.0, 1.0, 1.0);

    return ambient + diffuse + specular + reflectCol;
}

vec3 waveNormal(float x, float z) {
    float dx = 0.0;
    float dy = 0.0;

    for (int i = 0; i < num; i++)
    {
        vec2 p = normalize(vec2(dirVals[i], dirVals[i+100]));
        dx += calcWaveDx(p, i, x, z);
        dy += calcWaveDy(p, i, x, z);
    }
    vec3 n = vec3(-dx, 1.0, -dy);
    return normalize(n);
}

float calcWaveDx(vec2 p, int i, float x, float z)
{
    float amplitude = 1 * pow(0.6, i);
    float frequency = 1 * pow(1.4, i);
    
    float ampConst = 0.5;
    return pow(e, ampConst*amplitude*sin(dot(p, vec2(x,z))*frequency + time)-1)*ampConst*amplitude*p.x*frequency*cos(frequency*dot(p, vec2(x,z)) + time);
}

float calcWaveDy(vec2 p, int i, float x, float z)
{
    float amplitude = 1 * pow(0.6, i);
    float frequency = 1 * pow(1.4, i);
    
    float ampConst = 0.5;
    return pow(e, ampConst*amplitude*sin(dot(p, vec2(x,z))*frequency + time)-1)*ampConst*amplitude*p.y*frequency*cos(frequency*dot(p, vec2(x,z)) + time);
}
