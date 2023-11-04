library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sensor_humedad is
    port (
        pin_entrada: in std_logic_vector(7 downto 0);
        pin_salida: out std_logic;
        inicio_tiempo: in std_logic;
        clk: in std_logic;
        servo_angulo: in integer range 0 to 180;  -- Ángulo del servo
        servo_pwm: out std_logic  -- Señal de PWM para control del servo
    );
end entity sensor_humedad;

architecture comportamiento of sensor_humedad is
    signal datos_sensor: std_logic_vector(39 downto 0);
    signal humedad: std_logic_vector(15 downto 0);
    signal temperatura: std_logic_vector(15 downto 0);
    signal checksuma: std_logic_vector(7 downto 0);
    signal datos_validos: std_logic := '0';

    signal umbral_humedad: integer := 40;
    signal umbral_menor_seco: integer := 25;
    signal umbral_mayor_mojado: integer := 80;
    signal angulo_descanso: integer := 0;
    signal media_rotacion: integer := 90;

begin
    proceso_sensor: process (clk)
    begin
        if rising_edge(clk) then
            if inicio_tiempo = '0' then
                datos_sensor <= (others => '0');
            end if;

            datos_sensor <= pin_entrada & datos_sensor(7 downto 0);

            pin_salida <= '1';

            if pin_entrada = "00000001" and datos_sensor(39) = '0' then
                humedad <= datos_sensor(38 downto 23);
                temperatura <= datos_sensor(22 downto 7);
                checksuma <= datos_sensor(7 downto 0);

                if (to_integer(unsigned(checksuma)) = to_integer(unsigned(humedad)) + to_integer(unsigned(temperatura))) then
                    datos_validos <= '1';
                else
                    datos_validos <= '0';
                end if;
            end if;
        end if;
    end process proceso_sensor;

    -- Proceso para el manejo de umbrales y control del servo
    process
    begin
        wait until rising_edge(clk);
        if (datos_validos = '1') then
            if (to_integer(unsigned(humedad)) > umbral_humedad and
                to_integer(unsigned(temperatura)) > umbral_menor_seco and
                to_integer(unsigned(temperatura)) < umbral_mayor_mojado) then
                -- Activa el servo (gira medio giro, 90°)
                angulo_descanso <= media_rotacion;
                -- Utiliza el módulo de control de servo para generar la señal PWM
                servo_angulo <= angulo_descanso;
                servo_pwm <= '1';  -- Activa el servo
            else
                -- Detiene el servo (o mantenerlo inactivo, 0°)
                angulo_descanso <= 0;
                -- Utiliza el módulo de control de servo para generar la señal PWM
                servo_angulo <= angulo_descanso;
                servo_pwm <= '0';  -- Detiene el servo
            end if;
        end if;
    end process;
end architecture comportamiento;
